import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/harvest_case.dart';
import '../models/plot_selection.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/case_service.dart';
import '../theme/app_theme.dart';
import '../widgets/form_helpers.dart';

/// Doubles as both the "New Plot Selection" form and the edit form for an
/// existing one — pass [existingCase] to edit. The backend only allows the
/// edit while the case is still SUBMITTED_FOR_PLANNING (SOW 5.3 C: "Plot
/// Selection Team can edit only until Planning Team starts the plan");
/// this screen mirrors that by only being reachable for editable cases
/// (see PlotSelectionListScreen), and the PUT call still gets a real 403
/// from the backend if that's changed out from under the user in the
/// meantime — the client-side check is a convenience, not the enforcement.
class PlotSelectionFormScreen extends StatefulWidget {
  final HarvestCase? existingCase;

  const PlotSelectionFormScreen({super.key, this.existingCase});

  bool get isEditing => existingCase != null;

  @override
  State<PlotSelectionFormScreen> createState() => _PlotSelectionFormScreenState();
}

class _PlotSelectionFormScreenState extends State<PlotSelectionFormScreen>
    with SubmitStateMixin<PlotSelectionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFmt = DateFormat('dd MMM yyyy');

  final _locationController = TextEditingController();
  final _agentController = TextEditingController();
  final _farmerController = TextEditingController();
  final _farmerPhoneController = TextEditingController();
  final _villageController = TextEditingController();
  final _plantsController = TextEditingController();
  final _remarkController = TextEditingController();
  final _volumeController = TextEditingController();
  final _recoveryController = TextEditingController();
  final _pulpController = TextEditingController();
  final _companyController = TextEditingController();
  final _plotCodeController = TextEditingController();
  final _gpsController = TextEditingController();

  DateTime? _visitDate;
  DateTime? _harvestingDate;
  String _priority = 'medium';

  /// Server fileKey (e.g. "plot-photos/&lt;uuid&gt;.jpg") once uploaded — the
  /// previous version of this screen had no photo picker at all.
  String? _photoKey;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingCase?.selection;
    if (existing != null) {
      _locationController.text = existing.location;
      _agentController.text = existing.commissionAgentName;
      _farmerController.text = existing.farmerName;
      _farmerPhoneController.text = existing.farmerPhone;
      _villageController.text = existing.village;
      _plantsController.text = existing.numberOfPlants.toString();
      _remarkController.text = existing.remark;
      _volumeController.text = existing.volume.toString();
      _recoveryController.text = existing.recovery.toString();
      _pulpController.text = existing.pulp.toString();
      _companyController.text = existing.selectedCompany;
      _plotCodeController.text = existing.plotCode;
      _gpsController.text = existing.gpsNote;
      _visitDate = existing.visitDate;
      _harvestingDate = existing.harvestingDate;
      _priority = existing.priority;
      _photoKey = existing.photoPath;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _locationController,
      _agentController,
      _farmerController,
      _farmerPhoneController,
      _villageController,
      _plantsController,
      _remarkController,
      _volumeController,
      _recoveryController,
      _pulpController,
      _companyController,
      _plotCodeController,
      _gpsController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({required bool isVisitDate}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isVisitDate ? _visitDate : _harvestingDate) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    setState(() {
      if (isVisitDate) {
        _visitDate = picked;
      } else {
        _harvestingDate = picked;
      }
    });
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final XFile? picked;
    try {
      picked = await picker.pickImage(source: ImageSource.camera, maxWidth: 1600);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the camera on this device.')),
      );
      return;
    }
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final res = await context.read<ApiClient>().uploadFile(
            '/api/uploads/plot-photo',
            bytes: bytes,
            filename: picked.name,
          );
      setState(() => _photoKey = res['fileKey'] as String?);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed. Check your connection and try again.')),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _numericValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (double.tryParse(value.trim()) == null) return 'Must be a number';
    return null;
  }

  /// Excludes the case being edited from its own duplicate check — without
  /// this, saving an edit without changing farmer/location/date would flag
  /// itself as a duplicate of itself.
  bool _isDuplicate(CaseService service) {
    return service.allCases.any((c) =>
        c.id != widget.existingCase?.id &&
        c.selection.farmerName.trim().toLowerCase() == _farmerController.text.trim().toLowerCase() &&
        c.selection.location.trim().toLowerCase() == _locationController.text.trim().toLowerCase() &&
        _harvestingDate != null &&
        c.selection.harvestingDate.year == _harvestingDate!.year &&
        c.selection.harvestingDate.month == _harvestingDate!.month &&
        c.selection.harvestingDate.day == _harvestingDate!.day);
  }

  void _submit() {
    if (_visitDate == null || _harvestingDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both visit date and harvesting date.')),
      );
      return;
    }

    if (_harvestingDate!.isBefore(_visitDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harvesting date cannot be before the visit date.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final caseService = context.read<CaseService>();

    if (_isDuplicate(caseService)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A selection already exists for this farmer, location, and harvesting date.',
          ),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    final selection = PlotSelection(
      location: _locationController.text.trim(),
      visitDate: _visitDate!,
      commissionAgentName: _agentController.text.trim(),
      farmerName: _farmerController.text.trim(),
      farmerPhone: _farmerPhoneController.text.trim(),
      village: _villageController.text.trim(),
      numberOfPlants: int.parse(_plantsController.text.trim()),
      harvestingDate: _harvestingDate!,
      remark: _remarkController.text.trim(),
      volume: double.parse(_volumeController.text.trim()),
      recovery: double.parse(_recoveryController.text.trim()),
      pulp: double.parse(_pulpController.text.trim()),
      selectedCompany: _companyController.text.trim(),
      plotCode: _plotCodeController.text.trim(),
      gpsNote: _gpsController.text.trim(),
      priority: _priority,
      photoPath: _photoKey,
    );

    final actor = context.read<AuthService>().username ?? 'Plot Selection Team';

    if (widget.isEditing) {
      submitAction(
        () => caseService.updatePlotSelection(widget.existingCase!, selection, actor: actor),
        successMessage: 'Plot selection updated.',
      );
    } else {
      submitAction(
        () => caseService.createPlotSelection(selection, actor: actor),
        successMessage: 'Submitted for Planning.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Plot Selection' : 'New Plot Selection')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.isEditing) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppTheme.primaryDark),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This case moves to view-only the moment Planning starts.',
                        style: TextStyle(fontSize: 12, color: AppTheme.primaryDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            _SectionHeader('Location & Visit'),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location *'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Date of Visit *',
              value: _visitDate,
              fmt: _dateFmt,
              onTap: () => _pickDate(isVisitDate: true),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _villageController,
              decoration: const InputDecoration(labelText: 'Village *'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _plotCodeController,
              decoration: const InputDecoration(labelText: 'Plot Identifier / Code'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _gpsController,
              decoration: const InputDecoration(labelText: 'GPS Note / Landmark'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _uploadingPhoto ? null : _pickPhoto,
              icon: _uploadingPhoto
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(_photoKey != null ? Icons.check_circle : Icons.camera_alt_outlined),
              label: Text(_uploadingPhoto
                  ? 'Uploading...'
                  : (_photoKey != null ? 'Photo Attached (tap to replace)' : 'Take Plot Photo')),
            ),

            const SizedBox(height: 24),
            _SectionHeader('Farmer & Agent'),
            TextFormField(
              controller: _farmerController,
              decoration: const InputDecoration(labelText: 'Farmer Name *'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _farmerPhoneController,
              decoration: const InputDecoration(labelText: 'Farmer Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _agentController,
              decoration: const InputDecoration(labelText: 'Commission Agent Name'),
            ),

            const SizedBox(height: 24),
            _SectionHeader('Harvesting Details'),
            _DateField(
              label: 'Harvesting Date *',
              value: _harvestingDate,
              fmt: _dateFmt,
              onTap: () => _pickDate(isVisitDate: false),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _plantsController,
              decoration: const InputDecoration(labelText: 'Number of Plants *'),
              keyboardType: TextInputType.number,
              validator: _numericValidator,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _volumeController,
                    decoration: const InputDecoration(labelText: 'Volume *'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: _numericValidator,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _recoveryController,
                    decoration: const InputDecoration(labelText: 'Recovery *'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: _numericValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pulpController,
              decoration: const InputDecoration(labelText: 'Pulp *'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _numericValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(labelText: 'Selected Company *'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: const [
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'low', child: Text('Low')),
              ],
              onChanged: (v) => setState(() => _priority = v ?? _priority),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _remarkController,
              decoration: const InputDecoration(labelText: 'Remark'),
              maxLines: 3,
            ),

            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: submitting ? null : _submit,
              icon: submitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(widget.isEditing ? Icons.save_outlined : Icons.send),
              label: Text(submitting
                  ? (widget.isEditing ? 'Saving...' : 'Submitting...')
                  : (widget.isEditing ? 'Save Changes' : 'Submit for Planning')),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryDark,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateFormat fmt;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.fmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          value == null ? 'Select date' : fmt.format(value!),
          style: TextStyle(color: value == null ? Colors.grey : Colors.black87),
        ),
      ),
    );
  }
}
