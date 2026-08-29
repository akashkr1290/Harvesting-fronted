import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/produce_image.dart';
import '../services/api_client.dart';
import '../services/produce_image_service.dart';
import '../theme/app_theme.dart';
import '../widgets/verification_badge.dart';

/// Phase 4 upload + verification screen — originally case-photos only;
/// Phase 5 generalized it to also work directly against a marketplace
/// listing (`listingId`), now that FARMER/FPO can upload straight from
/// their own listing (see ProduceImageController's Phase 5 listingId
/// parameter and its ownership check). Exactly one of [caseId]/[listingId]
/// is normally passed.
class ProduceImageScreen extends StatefulWidget {
  final String? caseId;
  final String? listingId;
  const ProduceImageScreen({super.key, this.caseId, this.listingId})
      : assert(caseId != null || listingId != null, 'Pass caseId or listingId.');

  @override
  State<ProduceImageScreen> createState() => _ProduceImageScreenState();
}

class _ProduceImageScreenState extends State<ProduceImageScreen> {
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = context.read<ProduceImageService>();
      if (widget.listingId != null) {
        service.fetchForListing(widget.listingId!);
      } else {
        service.fetchForCase(widget.caseId!);
      }
    });
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    final picker = ImagePicker();
    XFile? picked;
    try {
      picked = await picker.pickImage(source: source, maxWidth: 1600);
    } catch (_) {
      _showMessage('Could not open the ${source == ImageSource.camera ? 'camera' : 'gallery'} on this device.');
      return;
    }
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final service = context.read<ProduceImageService>();
      final hasImages = service.images.isNotEmpty;
      final image = await service.upload(
        caseId: widget.caseId,
        listingId: widget.listingId,
        bytes: bytes,
        filename: picked.name,
        isPrimary: !hasImages, // first photo defaults to primary
      );
      if (!mounted) return;
      if (image.decision == ImageDecision.reject) {
        _showMessage('This photo was rejected: ${image.verificationStatus.label}. Please try another photo.');
      } else if (image.decision == ImageDecision.manualReview) {
        _showMessage('Photo uploaded — flagged for review before it appears on the marketplace.');
      } else {
        _showMessage('Photo uploaded and verified.');
      }
    } on ApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Upload failed. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _reverify(ProduceImage image) async {
    try {
      await context.read<ProduceImageService>().reverify(image.id);
    } on ApiException catch (e) {
      _showMessage(e.message);
    }
  }

  Future<void> _delete(ProduceImage image) async {
    try {
      await context.read<ProduceImageService>().deleteImage(image.id);
    } on ApiException catch (e) {
      _showMessage(e.message);
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ProduceImageService>();
    final apiClient = context.read<ApiClient>();

    return Scaffold(
      appBar: AppBar(title: const Text('Produce Photos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uploading ? null : () => _pickAndUpload(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uploading ? null : () => _pickAndUpload(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
          ),
          if (_uploading) const LinearProgressIndicator(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Every photo is automatically screened for signs of AI generation or editing. '
                'Results are a risk indicator, not a guarantee — flagged photos go to manual review.',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
          ),
          Expanded(
            child: service.isLoading && service.images.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : service.images.isEmpty
                    ? const Center(child: Text('No photos uploaded yet.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: service.images.length,
                        itemBuilder: (context, index) {
                          final image = service.images[index];
                          return _ProduceImageCard(
                            image: image,
                            imageUrl: apiClient.resolveUrl(image.url),
                            headers: apiClient.authHeaders,
                            onReverify: () => _reverify(image),
                            onDelete: () => _delete(image),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ProduceImageCard extends StatelessWidget {
  final ProduceImage image;
  final String imageUrl;
  final Map<String, String> headers;
  final VoidCallback onReverify;
  final VoidCallback onDelete;

  const _ProduceImageCard({
    required this.image,
    required this.imageUrl,
    required this.headers,
    required this.onReverify,
    required this.onDelete,
  });

  bool get _canRetry =>
      image.decision == ImageDecision.reject || image.decision == ImageDecision.manualReview;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.network(
              imageUrl,
              headers: headers,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.black12,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image, color: Colors.black38),
              ),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : const Center(child: CircularProgressIndicator()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    VerificationBadge(status: image.verificationStatus),
                    const Spacer(),
                    if (image.isPrimary)
                      const Icon(Icons.star, color: AppTheme.accent, size: 18),
                  ],
                ),
                if (image.verificationReasons.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...image.verificationReasons.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('• $r', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (_canRetry)
                      TextButton.icon(
                        onPressed: onReverify,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Re-check'),
                      ),
                    const Spacer(),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                      tooltip: 'Remove photo',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
