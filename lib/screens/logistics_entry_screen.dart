import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/harvest_case.dart';
import '../models/logistics_entry.dart';
import '../services/auth_service.dart';
import '../services/case_service.dart';
import '../widgets/case_card.dart';
import '../widgets/form_helpers.dart';
import 'route_optimization_screen.dart';

/// Handles both Pickup (Step 6) and Transport (Step 8) — same shape:
/// a name, an amount, an optional advance payment, optional remarks.
class LogisticsEntryScreen extends StatefulWidget {
  final HarvestCase harvestCase;
  final LogisticsKind kind;

  const LogisticsEntryScreen({super.key, required this.harvestCase, required this.kind});

  @override
  State<LogisticsEntryScreen> createState() => _LogisticsEntryScreenState();
}

class _LogisticsEntryScreenState extends State<LogisticsEntryScreen>
    with SubmitStateMixin<LogisticsEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _advanceController = TextEditingController(text: '0');
  final _remarksController = TextEditingController();

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final entry = LogisticsEntry(
      kind: widget.kind,
      personOrContractorName: _nameController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      advancePayment: double.tryParse(_advanceController.text.trim()) ?? 0,
      remarks: _remarksController.text.trim(),
    );

    final actor = context.read<AuthService>().username ?? widget.kind.label;
    final service = context.read<CaseService>();
    submitAction(
      () => widget.kind == LogisticsKind.pickup
          ? service.addPickup(widget.harvestCase, entry, actor: actor)
          : service.addTransport(widget.harvestCase, entry, actor: actor),
      successMessage: '${widget.kind.label} details saved.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.kind.label} Entry')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CaseCard(harvestCase: widget.harvestCase),
            if (widget.harvestCase.marketOrderId != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RouteOptimizationScreen(caseId: widget.harvestCase.id),
                  ),
                ),
                icon: const Icon(Icons.route_outlined),
                label: const Text('Optimize Marketplace Delivery Route'),
              ),
            ],
            const SizedBox(height: 16),
            SectionHeader(widget.kind.label),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: '${widget.kind.personLabel} *'),
              validator: requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount *', prefixText: '₹ '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: numericValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _advanceController,
              decoration: const InputDecoration(labelText: 'Advance Payment', prefixText: '₹ '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _remarksController,
              decoration: const InputDecoration(labelText: 'Remarks'),
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
              label: Text(submitting ? 'Saving...' : 'Save & Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
