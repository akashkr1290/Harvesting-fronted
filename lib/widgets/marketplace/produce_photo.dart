import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_client.dart';

/// Displays a produce photo served from `/api/files/...`. File serving is
/// authenticated the same as every other endpoint, so this can't be a
/// plain Image.network — it has to send the JWT as a header, same as
/// ApiClient does for every other request.
class ProducePhoto extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ProducePhoto({super.key, required this.url, this.width, this.height, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiClient>();
    return Image.network(
      api.fileUri(url).toString(),
      headers: api.authHeaders,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade100,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }
}

/// Placeholder shown where a photo would go but none has been uploaded yet.
class ProducePhotoPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;

  const ProducePhotoPlaceholder({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_outlined, color: Colors.grey, size: 32),
    );
  }
}
