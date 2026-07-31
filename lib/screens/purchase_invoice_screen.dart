import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/harvest_case.dart';
import '../services/auth_service.dart';
import '../services/case_service.dart';
import '../theme/app_theme.dart';
import '../widgets/case_card.dart';
import '../widgets/form_helpers.dart';

class PurchaseInvoiceScreen extends StatefulWidget {
  final HarvestCase harvestCase;
  const PurchaseInvoiceScreen({super.key, required this.harvestCase});

  @override
  State<PurchaseInvoiceScreen> createState() => _PurchaseInvoiceScreenState();
}

class _PurchaseInvoiceScreenState extends State<PurchaseInvoiceScreen>
    with SubmitStateMixin<PurchaseInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _rateController;
  late final TextEditingController _weightController;
  final _commissionController = TextEditingController(text: '0');
  final _packingController = TextEditingController(text: '0');
  final _transportController = TextEditingController(text: '0');
  final _otherController = TextEditingController(text: '0');
  final _deductionsController = TextEditingController(text: '0');
  final _additionsController = TextEditingController(text: '0');

  bool _includeCommission = true;
  bool _includePacking = true;
  bool _includeTransport = true;

  double _net = 0;

  @override
  void initState() {
    super.initState();
    final c = widget.harvestCase;
    _rateController = TextEditingController(text: (c.ratePerUnit ?? 0).toString());
    _weightController = TextEditingController(text: (c.completion?.actualWeight ?? c.selection.volume).toString());
    _transportController.text = c.transport?.amount.toString() ?? '0';
    _recalculate();
  }

  void _recalculate() {
    final rate = double.tryParse(_rateController.text) ?? 0;
    final weight = double.tryParse(_weightController.text) ?? 0;
    double net = rate * weight;
    if (_includeCommission) net -= double.tryParse(_commissionController.text) ?? 0;
    if (_includePacking) net -= double.tryParse(_packingController.text) ?? 0;
    if (_includeTransport) net -= double.tryParse(_transportController.text) ?? 0;
    net -= double.tryParse(_otherController.text) ?? 0;
    net -= double.tryParse(_deductionsController.text) ?? 0;
    net += double.tryParse(_additionsController.text) ?? 0;
    setState(() => _net = net);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final actor = context.read<AuthService>().username ?? 'Purchase Account Team';
    submitActionWithResult(
      () => context.read<CaseService>().createPurchaseInvoice(
            widget.harvestCase,
            rate: double.parse(_rateController.text),
            weight: double.parse(_weightController.text),
            includeCommission: _includeCommission,
            commissionAmount: double.tryParse(_commissionController.text) ?? 0,
            includePacking: _includePacking,
            packingCost: double.tryParse(_packingController.text) ?? 0,
            includeTransport: _includeTransport,
            transportCost: double.tryParse(_transportController.text) ?? 0,
            otherCharges: double.tryParse(_otherController.text) ?? 0,
            deductions: double.tryParse(_deductionsController.text) ?? 0,
            additions: double.tryParse(_additionsController.text) ?? 0,
            actor: actor,
          ),
      successMessage: (invoice) =>
          'Invoice ${invoice.invoiceNumber} generated. Net payable ₹${invoice.netPayable.toStringAsFixed(2)}',
    );
  }

  Widget _toggleAmountRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onToggle,
    required TextEditingController controller,
  }) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: (v) => onToggle(v ?? value)),
        Expanded(child: Text(label)),
        SizedBox(
          width: 110,
          child: TextFormField(
            controller: controller,
            enabled: value,
            onChanged: (_) => _recalculate(),
            decoration: const InputDecoration(prefixText: '₹ ', isDense: true),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.harvestCase;
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Invoice')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CaseCard(harvestCase: c),
            const SizedBox(height: 16),
            const SectionHeader('Auto-Pulled Data'),
            LabeledValue(label: 'Farmer', value: c.selection.farmerName),
            LabeledValue(label: 'Commission Agent', value: c.selection.commissionAgentName),
            LabeledValue(label: 'Actual Weight', value: '${c.completion?.actualWeight ?? '—'} kg'),
            const SizedBox(height: 20),
            const SectionHeader('Base Amount'),
            TextFormField(
              controller: _rateController,
              decoration: const InputDecoration(labelText: 'Rate per Unit *', prefixText: '₹ '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: numericValidator,
              onChanged: (_) => _recalculate(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(labelText: 'Weight / Quantity *'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: numericValidator,
              onChanged: (_) => _recalculate(),
            ),
            const SizedBox(height: 20),
            const SectionHeader('Deductions (toggle components on/off)'),
            _toggleAmountRow(
              label: 'Commission',
              value: _includeCommission,
              onToggle: (v) {
                setState(() => _includeCommission = v);
                _recalculate();
              },
              controller: _commissionController,
            ),
            _toggleAmountRow(
              label: 'Packing Material Cost',
              value: _includePacking,
              onToggle: (v) {
                setState(() => _includePacking = v);
                _recalculate();
              },
              controller: _packingController,
            ),
            _toggleAmountRow(
              label: 'Transport Cost',
              value: _includeTransport,
              onToggle: (v) {
                setState(() => _includeTransport = v);
                _recalculate();
              },
              controller: _transportController,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _otherController,
              decoration: const InputDecoration(labelText: 'Other Charges', prefixText: '₹ '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _recalculate(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _deductionsController,
                    decoration: const InputDecoration(labelText: 'Other Deductions', prefixText: '₹ '),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _recalculate(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _additionsController,
                    decoration: const InputDecoration(labelText: 'Additions', prefixText: '₹ '),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _recalculate(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              color: AppTheme.primary.withOpacity(0.08),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Net Payable to Farmer', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('₹${_net.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primaryDark)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: submitting ? null : _submit,
              icon: submitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.receipt_long_outlined),
              label: Text(submitting ? 'Generating...' : 'Generate Invoice & Complete Purchase'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Once generated, download or share the invoice PDF from Browse Cases.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
