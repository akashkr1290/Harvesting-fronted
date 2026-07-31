import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/harvest_case.dart';
import '../services/auth_service.dart';
import '../services/case_service.dart';
import '../theme/app_theme.dart';
import '../widgets/case_card.dart';
import '../widgets/form_helpers.dart';

class SalesInvoiceScreen extends StatefulWidget {
  final HarvestCase harvestCase;
  const SalesInvoiceScreen({super.key, required this.harvestCase});

  @override
  State<SalesInvoiceScreen> createState() => _SalesInvoiceScreenState();
}

class _SalesInvoiceScreenState extends State<SalesInvoiceScreen>
    with SubmitStateMixin<SalesInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _buyerController;
  final _rateController = TextEditingController();
  late final TextEditingController _weightController;
  final _taxController = TextEditingController(text: '0');

  double _total = 0;

  @override
  void initState() {
    super.initState();
    final c = widget.harvestCase;
    _buyerController = TextEditingController(text: c.selection.selectedCompany);
    _weightController =
        TextEditingController(text: (c.completion?.actualWeight ?? c.selection.volume).toString());
    _recalculate();
  }

  void _recalculate() {
    final rate = double.tryParse(_rateController.text) ?? 0;
    final weight = double.tryParse(_weightController.text) ?? 0;
    final tax = double.tryParse(_taxController.text) ?? 0;
    final subtotal = rate * weight;
    setState(() => _total = subtotal + subtotal * (tax / 100));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final actor = context.read<AuthService>().username ?? 'Accounts Team';
    submitActionWithResult(
      () => context.read<CaseService>().createSalesInvoice(
            widget.harvestCase,
            buyerCompany: _buyerController.text.trim(),
            salesRate: double.parse(_rateController.text),
            weight: double.parse(_weightController.text),
            taxPercent: double.tryParse(_taxController.text) ?? 0,
            actor: actor,
          ),
      successMessage: (invoice) => 'Sales invoice ${invoice.invoiceNumber} generated.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales Invoice')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CaseCard(harvestCase: widget.harvestCase),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Note: sales-invoice scope is still being confirmed with the client '
                '(see open questions in the Working Approach doc) — this form covers '
                'the fields listed in SOW section 6 and may change.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            const SectionHeader('Buyer & Rate'),
            TextFormField(
              controller: _buyerController,
              decoration: const InputDecoration(labelText: 'Buyer Company *'),
              validator: requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rateController,
              decoration: const InputDecoration(labelText: 'Sales Rate *', prefixText: '₹ '),
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _taxController,
              decoration: const InputDecoration(labelText: 'Tax %'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _recalculate(),
            ),
            const SizedBox(height: 20),
            Card(
              color: AppTheme.primary.withOpacity(0.08),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total (incl. tax)', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('₹${_total.toStringAsFixed(2)}',
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
              label: Text(submitting ? 'Generating...' : 'Generate Sales Invoice'),
            ),
          ],
        ),
      ),
    );
  }
}
