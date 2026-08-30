import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/produce_listing.dart';
import '../../services/offer_service.dart';
import '../../widgets/form_helpers.dart';

class SubmitOfferScreen extends StatefulWidget {
  final ProduceListingDetail listing;

  const SubmitOfferScreen({super.key, required this.listing});

  @override
  State<SubmitOfferScreen> createState() => _SubmitOfferScreenState();
}

class _SubmitOfferScreenState extends State<SubmitOfferScreen> with SubmitStateMixin<SubmitOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.listing.quantity.toString());
    // Left blank rather than pre-filled with the listing's own asking price:
    // a pre-filled value here reads as "the price", not as a starting point
    // to negotiate down (or up) from — buyers were leaving it untouched.
    _priceController = TextEditingController();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// A buyer can't offer more than what's listed — the backend doesn't
  /// enforce this today (Phase 2 keeps the offer/order model simple, one
  /// listing → one accepted offer), so this is a friendly client-side
  /// nudge rather than a hard rule mirrored from an API error.
  String? _quantityValidator(String? value) {
    final base = positiveNumericValidator(value);
    if (base != null) return base;
    final parsed = double.parse(value!.trim());
    if (parsed > widget.listing.quantity) {
      return 'Only ${widget.listing.quantity.toStringAsFixed(0)} ${widget.listing.unit} available';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final quantity = double.parse(_quantityController.text.trim());
    final price = double.parse(_priceController.text.trim());
    final message = _messageController.text.trim();

    submitAction(
      () => context.read<OfferService>().submit(
            widget.listing.id,
            quantity: quantity,
            pricePerUnit: price,
            message: message.isEmpty ? null : message,
          ),
      successMessage: 'Offer submitted.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Offer')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(widget.listing.cropName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Listed at ₹${widget.listing.expectedPricePerUnit.toStringAsFixed(2)} / ${widget.listing.unit} · '
              '${widget.listing.quantity.toStringAsFixed(0)} ${widget.listing.unit} available',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(labelText: 'Quantity (${widget.listing.unit}) *'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _quantityValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Your Price per Unit (₹) *',
                helperText:
                    'Listing price: ₹${widget.listing.expectedPricePerUnit.toStringAsFixed(2)} — enter what you want to offer',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: positiveNumericValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: 'Message to the seller (optional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: submitting ? null : _submit,
              icon: submitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send),
              label: Text(submitting ? 'Submitting...' : 'Submit Offer'),
            ),
          ],
        ),
      ),
    );
  }
}
