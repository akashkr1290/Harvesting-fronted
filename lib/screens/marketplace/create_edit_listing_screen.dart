import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/listing_status.dart';
import '../../models/produce_listing.dart';
import '../../services/api_client.dart';
import '../../services/marketplace_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/form_helpers.dart';
import '../../widgets/marketplace/produce_photo.dart';

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
  List<String> _imageUrls = [];
  bool _uploadingPhoto = false;

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
      _imageUrls = List.of(existing.imageUrls);
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

  /// Uploads a photo via the existing storage flow, then — if this listing
  /// already exists — immediately attaches it server-side too, so a photo
  /// added to an existing draft doesn't get lost if the user backs out
  /// without pressing Save.
  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final XFile? picked;
    try {
      picked = await picker.pickImage(source: ImageSource.camera, maxWidth: 1600);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the camera on this device.')),
      );
      return;
    }
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final res = await context.read<ApiClient>().uploadFile(
            '/api/uploads/produce-photo',
            bytes: bytes,
            filename: picked.name,
          );
      final url = res['url'] as String?;
      if (url == null) throw Exception('Upload succeeded but returned no url.');

      if (widget.isEditing) {
        await context.read<MarketplaceService>().addImages(widget.existingListing!.id, [url]);
      }
      setState(() => _imageUrls = [..._imageUrls, url]);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed. Check your connection and try again.')),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _submit() {
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
      submitActionWithResult<ProduceListingDetail>(
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
      ).then((_) {
        if (mounted) Navigator.of(context).pop(true);
      });
    } else {
      submitActionWithResult<ProduceListingDetail>(
        () async {
          final created = await service.createListing(
            cropName: cropName,
            quantity: quantity,
            unit: unit,
            quality: quality.isEmpty ? null : quality,
            harvestDate: _harvestDate!,
            location: location,
            expectedPricePerUnit: price,
            description: description.isEmpty ? null : description,
          );
          if (_imageUrls.isNotEmpty) {
            await service.addImages(created.id, _imageUrls);
          }
          return created;
        },
        successMessage: (_) => 'Listing created as a draft. Publish it when you\'re ready.',
        popOnSuccess: false,
      ).then((_) {
        if (mounted) Navigator.of(context).pop(true);
      });
    }
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
            const SectionHeader('Photos'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final url in _imageUrls)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ProducePhoto(url: url, width: 72, height: 72),
                  ),
                OutlinedButton.icon(
                  onPressed: _uploadingPhoto ? null : _pickPhoto,
                  icon: _uploadingPhoto
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.camera_alt_outlined),
                  label: Text(_uploadingPhoto ? 'Uploading...' : 'Add Photo'),
                ),
              ],
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
