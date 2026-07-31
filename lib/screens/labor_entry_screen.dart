import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/harvest_case.dart';
import '../models/logistics_entry.dart';
import '../services/auth_service.dart';
import '../services/case_service.dart';
import '../widgets/case_card.dart';
import '../widgets/form_helpers.dart';

class LaborEntryScreen extends StatefulWidget {
  final HarvestCase harvestCase;
  const LaborEntryScreen({super.key, required this.harvestCase});

  @override
  State<LaborEntryScreen> createState() => _LaborEntryScreenState();
}

class _LaborEntryScreenState extends State<LaborEntryScreen>
    with SubmitStateMixin<LaborEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _laborNameController = TextEditingController();
  final _laborAmountController = TextEditingController();
  final _laborRemarksController = TextEditingController(); // also carries "other cost e.g. Petrol"

  bool _includeLocalLabor = false;
  final _localNameController = TextEditingController();
  final _localAmountController = TextEditingController();

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final labor = LogisticsEntry(
      kind: LogisticsKind.labor,
      personOrContractorName: _laborNameController.text.trim(),
      amount: double.parse(_laborAmountController.text.trim()),
      remarks: _laborRemarksController.text.trim(),
    );

    LogisticsEntry? localLabor;
    if (_includeLocalLabor && _localNameController.text.trim().isNotEmpty) {
      localLabor = LogisticsEntry(
        kind: LogisticsKind.localLabor,
        personOrContractorName: _localNameController.text.trim(),
        amount: double.tryParse(_localAmountController.text.trim()) ?? 0,
      );
    }

    final actor = context.read<AuthService>().username ?? 'Labor Coordinator';
    submitAction(
      () => context.read<CaseService>().addLaborEntries(
            widget.harvestCase,
            labor: labor,
            localLabor: localLabor,
            actor: actor,
          ),
      successMessage: 'Cost entries saved. Forwarded to Godown for material return.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Labor Cost Entry')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CaseCard(harvestCase: widget.harvestCase),
            const SizedBox(height: 16),
            const SectionHeader('Labor'),
            TextFormField(
              controller: _laborNameController,
              decoration: const InputDecoration(labelText: 'Labor Contractor Name *'),
              validator: requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _laborAmountController,
              decoration: const InputDecoration(labelText: 'Amount *', prefixText: '₹ '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: numericValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _laborRemarksController,
              decoration: const InputDecoration(labelText: 'Other Cost (e.g. Petrol) / Remarks'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Add Local Labor (if any)'),
              value: _includeLocalLabor,
              onChanged: (v) => setState(() => _includeLocalLabor = v),
            ),
            if (_includeLocalLabor) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _localNameController,
                decoration: const InputDecoration(labelText: 'Local Labor Contractor Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _localAmountController,
                decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
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
              label: Text(submitting ? 'Saving...' : 'Save & Forward to Godown'),
            ),
          ],
        ),
      ),
    );
  }
}
