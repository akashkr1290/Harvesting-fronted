import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/harvest_case.dart';
import '../models/master_item.dart';
import '../models/packing_material.dart';
import '../services/auth_service.dart';
import '../services/case_service.dart';
import '../services/master_data_service.dart';
import '../widgets/case_card.dart';
import '../widgets/form_helpers.dart';

class GodownIssueScreen extends StatefulWidget {
  final HarvestCase harvestCase;
  const GodownIssueScreen({super.key, required this.harvestCase});

  @override
  State<GodownIssueScreen> createState() => _GodownIssueScreenState();
}

class _PackingLineInput {
  String? itemName;
  final TextEditingController qtyController = TextEditingController();
}

class _GodownIssueScreenState extends State<GodownIssueScreen>
    with SubmitStateMixin<GodownIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _receiverController = TextEditingController();
  final _remarksController = TextEditingController();
  final List<_PackingLineInput> _lines = [_PackingLineInput()];

  void _addLine() => setState(() => _lines.add(_PackingLineInput()));

  void _removeLine(int index) {
    if (_lines.length == 1) return;
    setState(() => _lines.removeAt(index));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final validLines = <PackingMaterialLine>[];
    for (final line in _lines) {
      if (line.itemName == null || line.qtyController.text.trim().isEmpty) continue;
      final qty = double.tryParse(line.qtyController.text.trim());
      if (qty == null) continue;
      validLines.add(PackingMaterialLine(itemName: line.itemName!, quantity: qty));
    }

    if (validLines.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Add at least one packing item with quantity.')));
      return;
    }

    final record = PackingMaterialRecord(
      dateTime: DateTime.now(),
      handledBy: _receiverController.text.trim(),
      lines: validLines,
      remarks: _remarksController.text.trim(),
    );

    final actor = context.read<AuthService>().username ?? 'Godown Team';
    submitAction(
      () => context.read<CaseService>().issuePackingMaterial(widget.harvestCase, record, actor: actor),
      successMessage: 'Packing material issued. Forwarded to Supervisor.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final packingItems = context.watch<MasterDataService>().activeItemsFor(MasterCategory.packingItems);

    return Scaffold(
      appBar: AppBar(title: const Text('Issue Packing Material')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CaseCard(harvestCase: widget.harvestCase),
            const SizedBox(height: 16),
            const SectionHeader('Packing Items'),
            ..._lines.asMap().entries.map((entry) {
              final index = entry.key;
              final line = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: line.itemName,
                        decoration: const InputDecoration(labelText: 'Item'),
                        items: packingItems
                            .map((MasterItem i) => DropdownMenuItem(value: i.name, child: Text(i.name)))
                            .toList(),
                        onChanged: (v) => setState(() => line.itemName = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: line.qtyController,
                        decoration: const InputDecoration(labelText: 'Qty'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeLine(index),
                      icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: _addLine,
              icon: const Icon(Icons.add),
              label: const Text('Add another item'),
            ),
            const SizedBox(height: 16),
            const SectionHeader('Issue Details'),
            TextFormField(
              controller: _receiverController,
              decoration: const InputDecoration(labelText: 'Issued To (Packing Team / Receiver) *'),
              validator: requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _remarksController,
              decoration: const InputDecoration(labelText: 'Remarks (shortage, partial issue, etc.)'),
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
                  : const Icon(Icons.local_shipping_outlined),
              label: Text(submitting ? 'Issuing...' : 'Issue & Forward to Supervisor'),
            ),
          ],
        ),
      ),
    );
  }
}
