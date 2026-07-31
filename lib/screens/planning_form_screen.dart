import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/harvest_case.dart';
import '../models/planning_details.dart';
import '../services/auth_service.dart';
import '../services/case_service.dart';
import '../widgets/case_card.dart';
import '../widgets/form_helpers.dart';

class PlanningFormScreen extends StatefulWidget {
  final HarvestCase harvestCase;
  const PlanningFormScreen({super.key, required this.harvestCase});

  @override
  State<PlanningFormScreen> createState() => _PlanningFormScreenState();
}

class _PlanningFormScreenState extends State<PlanningFormScreen>
    with SubmitStateMixin<PlanningFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _timeWindowController = TextEditingController(text: 'Morning (6 AM – 10 AM)');
  final _supervisorController = TextEditingController();
  final _pickupPersonController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _expectedQtyController = TextEditingController();
  final _godownNotesController = TextEditingController();
  final _supervisorNotesController = TextEditingController();

  DateTime? _plannedDate;

  @override
  void initState() {
    super.initState();
    _plannedDate = widget.harvestCase.selection.harvestingDate;
    _expectedQtyController.text = widget.harvestCase.selection.volume.toString();
  }

  @override
  void dispose() {
    for (final c in [
      _timeWindowController,
      _supervisorController,
      _pickupPersonController,
      _vehicleController,
      _expectedQtyController,
      _godownNotesController,
      _supervisorNotesController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _plannedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _plannedDate = picked);
  }

  void _submit() {
    if (_plannedDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a planned harvesting date.')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final details = PlanningDetails(
      plannedDate: _plannedDate!,
      timeWindow: _timeWindowController.text.trim(),
      supervisorName: _supervisorController.text.trim(),
      pickupPersonName: _pickupPersonController.text.trim(),
      vehiclePlan: _vehicleController.text.trim(),
      expectedQuantity: double.parse(_expectedQtyController.text.trim()),
      notesForGodown: _godownNotesController.text.trim(),
      notesForSupervisor: _supervisorNotesController.text.trim(),
    );

    final actor = context.read<AuthService>().username ?? 'Planning Team';
    submitAction(
      () => context.read<CaseService>().savePlanning(widget.harvestCase, details, actor: actor),
      successMessage: 'Plan saved and forwarded to Godown Team.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Harvest Plan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CaseCard(harvestCase: widget.harvestCase),
            const SizedBox(height: 16),
            const SectionHeader('Schedule'),
            DateField(
              label: 'Planned Harvesting Date *',
              value: _plannedDate,
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _timeWindowController,
              decoration: const InputDecoration(labelText: 'Time Window'),
              validator: requiredValidator,
            ),
            const SizedBox(height: 20),
            const SectionHeader('Team Assignment'),
            TextFormField(
              controller: _supervisorController,
              decoration: const InputDecoration(labelText: 'Supervisor Name *'),
              validator: requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pickupPersonController,
              decoration: const InputDecoration(labelText: 'Pickup Person *'),
              validator: requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _vehicleController,
              decoration: const InputDecoration(labelText: 'Vehicle Plan'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _expectedQtyController,
              decoration: const InputDecoration(labelText: 'Expected Quantity *'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: numericValidator,
            ),
            const SizedBox(height: 20),
            const SectionHeader('Notes'),
            TextFormField(
              controller: _godownNotesController,
              decoration: const InputDecoration(labelText: 'Notes for Godown Team'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _supervisorNotesController,
              decoration: const InputDecoration(labelText: 'Notes for Supervisor'),
              maxLines: 2,
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
              label: Text(submitting ? 'Saving...' : 'Save Plan & Forward to Godown'),
            ),
          ],
        ),
      ),
    );
  }
}
