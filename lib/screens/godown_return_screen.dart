import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/harvest_case.dart';
import '../models/packing_material.dart';
import '../services/auth_service.dart';
import '../services/case_service.dart';
import '../widgets/case_card.dart';
import '../widgets/form_helpers.dart';

class GodownReturnScreen extends StatefulWidget {
  final HarvestCase harvestCase;
  const GodownReturnScreen({super.key, required this.harvestCase});

  @override
  State<GodownReturnScreen> createState() => _GodownReturnScreenState();
}

class _GodownReturnScreenState extends State<GodownReturnScreen>
    with SubmitStateMixin<GodownReturnScreen> {
  final _formKey = GlobalKey<FormState>();
  final _remarksController = TextEditingController();
  late final Map<String, TextEditingController> _returnControllers;

  @override
  void initState() {
    super.initState();
    final issued = widget.harvestCase.packingIssue?.lines ?? [];
    _returnControllers = {for (final line in issued) line.itemName: TextEditingController(text: '0')};
  }

  double _issuedQty(String itemName) {
    final issued = widget.harvestCase.packingIssue?.lines ?? [];
    return issued.firstWhere((l) => l.itemName == itemName).quantity;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final lines = <PackingMaterialLine>[];
    _returnControllers.forEach((itemName, controller) {
      final qty = double.tryParse(controller.text.trim()) ?? 0;
      lines.add(PackingMaterialLine(itemName: itemName, quantity: qty));
    });

    final record = PackingMaterialRecord(
      dateTime: DateTime.now(),
      handledBy: context.read<AuthService>().username ?? 'Godown Team',
      lines: lines,
      remarks: _remarksController.text.trim(),
    );

    final actor = context.read<AuthService>().username ?? 'Godown Team';
    submitAction(
      () => context.read<CaseService>().returnPackingMaterial(widget.harvestCase, record, actor: actor),
      successMessage: 'Return recorded. Forwarded to Purchase Account Team.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Return Packing Material')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CaseCard(harvestCase: widget.harvestCase),
            const SizedBox(height: 16),
            const SectionHeader('Actual Consumption'),
            const Text(
              'Enter quantity returned per item — the difference from issued is treated as consumed, for inventory control.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (_returnControllers.isEmpty)
              const Text('No packing material issue record found for this case.',
                  style: TextStyle(color: Colors.grey))
            else
              ..._returnControllers.entries.map((entry) {
                final issued = _issuedQty(entry.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text('${entry.key}\n(issued: $issued)',
                            style: const TextStyle(fontSize: 13)),
                      ),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: entry.value,
                          decoration: const InputDecoration(labelText: 'Returned'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                );
              }),
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
                  : const Icon(Icons.assignment_turned_in_outlined),
              label: Text(submitting ? 'Reconciling...' : 'Reconcile & Forward to Purchase Account'),
            ),
          ],
        ),
      ),
    );
  }
}
