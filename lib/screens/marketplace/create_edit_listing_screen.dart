import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/listing_status.dart';
import '../../models/produce_listing.dart';
import '../../services/marketplace_service.dart';
import '../produce_image_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/form_helpers.dart';

/// Doubles as both "Create Listing" and "Edit Listing" — pass
/// [existingListing] to edit. The backend only allows edits while the
/// listing is still DRAFT, mirroring PlotSelectionFormScreen's approach to
/// the same kind of edit window on the harvest-ops side.
class CreateEditListingScreen extends StatefulWidget {
  final ProduceListingDetail? existingListing;

  const CreateEditListingScreen({super.key, this.existingListing});

  bool get isEditing => existingListing != null;

  @override
  State<CreateEditListingScreen> createState() => _CreateEditListingScreenState();
}

class _CreateEditListingScreenState extends State<CreateEditListingScreen> with SubmitStateMixin<CreateEditListingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _cropController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController(text: 'kg');
  final _qualityController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _harvestDate;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingListing;
    if (existing != null) {
      _cropController.text = existing.cropName;
      _quantityController.text = existing.quantity.toString();
      _unitController.text = existing.unit;
      _qualityController.text = existing.quality ?? '';
      _locationController.text = existing.location;
      _priceController.text = existing.expectedPricePerUnit.toString();
      _descriptionController.text = existing.description ?? '';
      _harvestDate = existing.harvestDate;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _cropController,
      _quantityController,
      _unitController,
      _qualityController,
      _locationController,
      _priceController,
      _descriptionController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _harvestDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() => _harvestDate = picked);
  }

  Future<void> _submit() async {
    if (_harvestDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a harvest date.')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final service = context.read<MarketplaceService>();
    final cropName = _cropController.text.trim();
    final quantity = double.parse(_quantityController.text.trim());
    final unit = _unitController.text.trim();
    final quality = _qualityController.text.trim();
    final location = _locationController.text.trim();
    final price = double.parse(_priceController.text.trim());
    final description = _descriptionController.text.trim();

    if (widget.isEditing) {
      await submitActionWithResult<ProduceListingDetail>(
        () => service.updateListing(
          widget.existingListing!.id,
          cropName: cropName,
          quantity: quantity,
          unit: unit,
          quality: quality.isEmpty ? null : quality,
          harvestDate: _harvestDate!,
          location: location,
          expectedPricePerUnit: price,
          description: description.isEmpty ? null : description,
        ),
        successMessage: (_) => 'Listing updated.',
        popOnSuccess: false,
      );
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    ProduceListingDetail? createdListing;
    await submitActionWithResult<ProduceListingDetail>(
      () async {
        createdListing = await service.createListing(
          cropName: cropName,
          quantity: quantity,
          unit: unit,
          quality: quality.isEmpty ? null : quality,
          harvestDate: _harvestDate!,
          location: location,
          expectedPricePerUnit: price,
          description: description.isEmpty ? null : description,
        );
        return createdListing!;
      },
      successMessage: (_) => 'Draft created. Add a verified crop photo before publishing.',
      popOnSuccess: false,
    );

    if (!mounted || createdListing == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProduceImageScreen(listingId: createdListing!.id)),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isDraft = widget.existingListing?.status != ListingStatus.published &&
        widget.existingListing?.status != ListingStatus.closed;

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Listing' : 'New Listing')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.isEditing && !isDraft) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppTheme.danger),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This listing is no longer a draft and can\'t be edited.',
                        style: TextStyle(fontSize: 12, color: AppTheme.danger),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            const SectionHeader('Produce'),
            TextFormField(
              controller: _cropController,
              decoration: const InputDecoration(labelText: 'Crop *'),
              validator: requiredValidator,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity *'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: positiveNumericValidator,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(labelText: 'Unit *'),
                    validator: requiredValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _qualityController,
              decoration: const InputDecoration(labelText: 'Quality (e.g. Grade A)'),
            ),
            const SizedBox(height: 12),
            DateField(label: 'Harvest Date *', value: _harvestDate, onTap: _pickDate),

            const SizedBox(height: 24),
            const SectionHeader('Location & Price'),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location *'),
              validator: requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Expected Price per Unit (₹) *'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: positiveNumericValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),

            const SizedBox(height: 24),
            const SectionHeader('Crop Photo & Verification'),
            if (widget.isEditing)
              OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProduceImageScreen(listingId: widget.existingListing!.id),
                    ),
                  );
                },
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Manage Crop Photos & Verification'),
              )
            else
              const Text(
                'First create the listing as a draft. The next screen will let you upload the actual crop photo and run verification before publishing.',
                style: TextStyle(color: Colors.black54, fontSize: 12),
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
                  : Icon(widget.isEditing ? Icons.save_outlined : Icons.send),
              label: Text(submitting
                  ? (widget.isEditing ? 'Saving...' : 'Creating...')
                  : (widget.isEditing ? 'Save Changes' : 'Create Listing')),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
