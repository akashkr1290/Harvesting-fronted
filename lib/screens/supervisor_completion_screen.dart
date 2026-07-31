import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/harvest_case.dart';
import '../models/harvest_completion.dart';
import '../services/auth_service.dart';
import '../services/case_service.dart';
import '../widgets/case_card.dart';
import '../widgets/form_helpers.dart';

class SupervisorCompletionScreen extends StatefulWidget {
  final HarvestCase harvestCase;
  const SupervisorCompletionScreen({super.key, required this.harvestCase});

  @override
  State<SupervisorCompletionScreen> createState() => _SupervisorCompletionScreenState();
}

class _SupervisorCompletionScreenState extends State<SupervisorCompletionScreen>
    with SubmitStateMixin<SupervisorCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bagsController = TextEditingController();
  final _weightController = TextEditingController();
  final _qualityController = TextEditingController();
  final _wastageController = TextEditingController();
  final _volumeController = TextEditingController();
  final _recoveryController = TextEditingController();
  final _pulpController = TextEditingController();
  final _remarksController = TextEditingController();

  DateTime? _actualDate;
  String? _weightSlipFileName;

  @override
  void initState() {
    super.initState();
    _actualDate = DateTime.now();
    final s = widget.harvestCase.selection;
    _volumeController.text = s.volume.toString();
    _recoveryController.text = s.recovery.toString();
    _pulpController.text = s.pulp.toString();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _actualDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _actualDate = picked);
  }

  Future<void> _pickWeightSlip() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file != null) setState(() => _weightSlipFileName = file.name);
    } catch (_) {
      // Platform may not support image_picker in this environment (e.g. web
      // without config); fall back to a mock filename so the flow still
      // demos end to end.
      setState(() => _weightSlipFileName = 'weight_slip_${DateTime.now().millisecondsSinceEpoch}.jpg');
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final completion = HarvestCompletion(
      actualDate: _actualDate ?? DateTime.now(),
      actualBagsOrCrates: int.tryParse(_bagsController.text.trim()) ?? 0,
      actualWeight: double.parse(_weightController.text.trim()),
      qualityNotes: _qualityController.text.trim(),
      wastageNotes: _wastageController.text.trim(),
      finalVolume: double.tryParse(_volumeController.text.trim()) ?? 0,
      finalRecovery: double.tryParse(_recoveryController.text.trim()) ?? 0,
      finalPulp: double.tryParse(_pulpController.text.trim()) ?? 0,
      remarks: _remarksController.text.trim(),
      weightSlipFileName: _weightSlipFileName,
    );

    final actor = context.read<AuthService>().username ?? 'Supervisor';
    submitAction(
      () => context.read<CaseService>().completeHarvest(widget.harvestCase, completion, actor: actor),
      successMessage: 'Harvest completion saved. Forwarded to Pickup.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Harvest Completion')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CaseCard(harvestCase: widget.harvestCase),
            const SizedBox(height: 16),
            const SectionHeader('Actuals'),
            DateField(label: 'Actual Harvest Date *', value: _actualDate, onTap: _pickDate),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bagsController,
              decoration: const InputDecoration(labelText: 'Actual Bags / Crates'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(labelText: 'Actual Weight (kg) *'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: numericValidator,
            ),
            const SizedBox(height: 20),
            const SectionHeader('Quality & Final Measurements'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _volumeController,
                    decoration: const InputDecoration(labelText: 'Final Volume'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _recoveryController,
                    decoration: const InputDecoration(labelText: 'Final Recovery'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pulpController,
              decoration: const InputDecoration(labelText: 'Final Pulp'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _qualityController,
              decoration: const InputDecoration(labelText: 'Quality Notes'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _wastageController,
              decoration: const InputDecoration(labelText: 'Wastage Notes'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _remarksController,
              decoration: const InputDecoration(labelText: 'Additional Remarks'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            const SectionHeader('Weight Slip'),
            OutlinedButton.icon(
              onPressed: _pickWeightSlip,
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(_weightSlipFileName ?? 'Upload Weight Slip Photo / PDF'),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: submitting ? null : _submit,
              icon: submitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(submitting ? 'Saving...' : 'Save & Forward to Pickup'),
            ),
          ],
        ),
      ),
    );
  }
}
