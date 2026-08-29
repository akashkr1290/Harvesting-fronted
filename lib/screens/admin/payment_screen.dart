import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/payment.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';

/// Records a MOCK payment against an existing PurchaseInvoice (farmer
/// payout) or SalesInvoice (buyer payment). No real payment gateway is
/// integrated anywhere in this app — see PaymentRecordView.isMock and the
/// banner below. This screen takes the invoice id directly rather than
/// looking it up, since neither invoice list currently surfaces its own id
/// to the widget tree; entering it here is a stand-in until a "Record
/// Payment" button is wired directly into those screens (see Phase 5 notes).
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _referenceIdController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  PaymentReferenceType _referenceType = PaymentReferenceType.purchaseInvoice;
  bool _submitting = false;
  PaymentRecordView? _result;

  @override
  void dispose() {
    _referenceIdController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _result = null;
    });
    try {
      final api = context.read<ApiClient>();
      final json = await api.post('/api/payments', body: {
        'referenceType': _referenceType.apiValue,
        'referenceId': _referenceIdController.text.trim(),
        'amount': double.parse(_amountController.text.trim()),
        if (_noteController.text.trim().isNotEmpty) 'note': _noteController.text.trim(),
      }) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _result = PaymentRecordView.fromApi(json));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not record the payment. Check your connection and try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Payment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.black87),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'MOCK payment recording — no real payment gateway is connected. '
                    'No money actually moves.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<PaymentReferenceType>(
                  value: _referenceType,
                  decoration: const InputDecoration(labelText: 'Payment for', border: OutlineInputBorder()),
                  items: PaymentReferenceType.values
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (v) => setState(() => _referenceType = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _referenceIdController,
                  decoration: const InputDecoration(labelText: 'Invoice ID', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount (INR)', border: OutlineInputBorder()),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null) return 'Enter a valid number';
                    if (n <= 0) return 'Must be greater than zero';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Record Payment'),
                  ),
                ),
              ],
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _result!.status == 'SUCCEEDED' ? Icons.check_circle : Icons.error,
                          color: _result!.status == 'SUCCEEDED' ? AppTheme.primary : AppTheme.danger,
                        ),
                        const SizedBox(width: 8),
                        Text(_result!.status, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('₹${_result!.amount.toStringAsFixed(2)} ${_result!.currency}'),
                    if (_result!.gatewayReference != null) Text('Reference: ${_result!.gatewayReference}'),
                    if (_result!.failureReason != null)
                      Text(_result!.failureReason!, style: const TextStyle(color: AppTheme.danger)),
                    const SizedBox(height: 4),
                    const Text('Simulated by the mock payment gateway — no real transaction.',
                        style: TextStyle(fontSize: 11, color: Colors.black45)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
