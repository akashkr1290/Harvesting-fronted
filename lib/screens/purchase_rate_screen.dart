import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/harvest_case.dart';
import '../services/auth_service.dart';
import '../services/case_service.dart';
import '../widgets/case_card.dart';
import '../widgets/form_helpers.dart';

/// Purchase Account Team reviews selected plots and updates the purchase
/// rate before Godown issues packing material (SOW section 4, Step 4).
class PurchaseRateScreen extends StatefulWidget {
  final HarvestCase harvestCase;
  const PurchaseRateScreen({super.key, required this.harvestCase});

  @override
  State<PurchaseRateScreen> createState() => _PurchaseRateScreenState();
}

class _PurchaseRateScreenState extends State<PurchaseRateScreen>
    with SubmitStateMixin<PurchaseRateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rateController = TextEditingController();

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final actor = context.read<AuthService>().username ?? 'Purchase Account Team';
    submitAction(
      () => context.read<CaseService>().updatePurchaseRate(
            widget.harvestCase,
            double.parse(_rateController.text.trim()),
            actor: actor,
          ),
      successMessage: 'Rate saved and forwarded to Godown Team.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final selection = widget.harvestCase.selection;
    return Scaffold(
      appBar: AppBar(title: const Text('Update Purchase Rate')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CaseCard(harvestCase: widget.harvestCase),
            const SizedBox(height: 16),
            const SectionHeader('Plot Reference'),
            LabeledValue(label: 'Farmer', value: selection.farmerName),
            LabeledValue(label: 'Company', value: selection.selectedCompany),
            LabeledValue(label: 'Expected Volume', value: selection.volume.toString()),
            const SizedBox(height: 16),
            const SectionHeader('Rate'),
            TextFormField(
              controller: _rateController,
              decoration: const InputDecoration(labelText: 'Rate per Unit *', prefixText: '₹ '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: numericValidator,
            ),
            const SizedBox(height: 8),
            const Text(
              'This rate is visible to the Purchase Account Team only, per the SOW '
              '(planning form is shared with account team, not the farmer).',
              style: TextStyle(color: Colors.grey, fontSize: 12),
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
              label: Text(submitting ? 'Saving...' : 'Save Rate & Forward to Godown'),
            ),
          ],
        ),
      ),
    );
  }
}
