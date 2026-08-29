import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/produce_image.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/verification_badge.dart';

/// Admin-only queue for images the automated checker routed to
/// MANUAL_REVIEW (SOW verification flow's "Manual Review" step, made
/// actionable). Reuses ProduceImage/VerificationBadge from the upload
/// screen — this is a second view over the same data, not a new model.
class AdminVerificationQueueScreen extends StatefulWidget {
  const AdminVerificationQueueScreen({super.key});

  @override
  State<AdminVerificationQueueScreen> createState() => _AdminVerificationQueueScreenState();
}

class _AdminVerificationQueueScreenState extends State<AdminVerificationQueueScreen> {
  bool _loading = true;
  String? _error;
  List<ProduceImage> _queue = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiClient>();
      final list = await api.get('/api/produce-images/review-queue') as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _queue = list.map((j) => ProduceImage.fromApi(j as Map<String, dynamic>)).toList();
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load the review queue. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openDetail(ProduceImage image) async {
    final decided = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _AdminReviewDetailScreen(image: image)),
    );
    if (decided == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verification Queue')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [
                    const SizedBox(height: 80),
                    Center(child: Text(_error!, style: const TextStyle(color: AppTheme.danger))),
                  ])
                : _queue.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 80),
                        Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text('Nothing waiting for review right now.',
                                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _queue.length,
                        itemBuilder: (context, index) {
                          final image = _queue[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const Icon(Icons.image_outlined),
                              title: Text(image.originalFilename ?? image.id),
                              subtitle: VerificationBadge(status: image.verificationStatus),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _openDetail(image),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

class _AdminReviewDetailScreen extends StatefulWidget {
  final ProduceImage image;
  const _AdminReviewDetailScreen({required this.image});

  @override
  State<_AdminReviewDetailScreen> createState() => _AdminReviewDetailScreenState();
}

class _AdminReviewDetailScreenState extends State<_AdminReviewDetailScreen> {
  final _noteController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _decide(String decision) async {
    setState(() => _submitting = true);
    try {
      final api = context.read<ApiClient>();
      await api.post('/api/produce-images/${widget.image.id}/admin-decision', body: {
        'decision': decision,
        if (_noteController.text.trim().isNotEmpty) 'note': _noteController.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(decision == 'ACCEPT' ? 'Photo accepted.' : 'Photo rejected.')),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not submit the decision. Check your connection and try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.image;
    final api = context.read<ApiClient>();

    return Scaffold(
      appBar: AppBar(title: const Text('Review Photo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                api.resolveUrl(image.url),
                headers: api.authHeaders,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.black12,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image, color: Colors.black38),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            VerificationBadge(status: image.verificationStatus),
            const SizedBox(width: 8),
            if (image.confidenceScore != null)
              Text('Confidence: ${(image.confidenceScore! * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          if (image.verificationReasons.isNotEmpty) ...[
            const Text('Signals from the automated check:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ...image.verificationReasons.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $r', style: const TextStyle(fontSize: 13)),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text('Uploaded ${image.uploadedAt.toLocal()}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Review note (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _submitting ? null : () => _decide('REJECT'),
                  icon: const Icon(Icons.close, color: AppTheme.danger),
                  label: const Text('Reject', style: TextStyle(color: AppTheme.danger)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : () => _decide('ACCEPT'),
                  icon: const Icon(Icons.check),
                  label: const Text('Accept'),
                ),
              ),
            ],
          ),
          if (_submitting) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
        ],
      ),
    );
  }
}
