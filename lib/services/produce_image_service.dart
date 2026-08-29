import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/produce_image.dart';

/// Real API-backed service for Phase 4's image upload + AI authenticity
/// verification. Mirrors CaseService's shape (cache + notifyListeners) but
/// scoped to one case's (or, since Phase 5, one listing's) images at a
/// time, since that's how every screen that needs this actually uses it.
class ProduceImageService extends ChangeNotifier {
  final ApiClient _api;
  final List<ProduceImage> _images = [];
  bool _loading = false;
  String? _error;

  ProduceImageService(this._api);

  bool get isLoading => _loading;
  String? get error => _error;
  List<ProduceImage> get images => List.unmodifiable(_images);

  Future<void> fetchForCase(String caseId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await _api.get('/api/produce-images/case/$caseId') as List<dynamic>;
      _images
        ..clear()
        ..addAll(list.map((j) => ProduceImage.fromApi(j as Map<String, dynamic>)));
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Phase 5: listing-scoped equivalent of [fetchForCase] — what the
  /// marketplace listing screens use now that FARMER/FPO can upload
  /// directly against a listing (see ProduceImageController's Phase 5
  /// listingId parameter).
  Future<void> fetchForListing(String listingId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await _api.get('/api/produce-images/listing/$listingId') as List<dynamic>;
      _images
        ..clear()
        ..addAll(list.map((j) => ProduceImage.fromApi(j as Map<String, dynamic>)));
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Uploads one photo for [caseId] and/or [listingId] and runs it straight
  /// through AI verification server-side; the returned image already
  /// carries its verification result — there's no separate "start
  /// verification" step for screens to poll (see ProduceImageService.upload
  /// on the backend). Exactly one of [caseId]/[listingId] is normally
  /// passed; both are optional so this one method serves both the
  /// case-photo flow and the Phase 5 listing-photo flow.
  Future<ProduceImage> upload({
    String? caseId,
    String? listingId,
    required List<int> bytes,
    required String filename,
    bool isPrimary = false,
  }) async {
    final params = <String>[
      if (caseId != null) 'caseId=${Uri.encodeQueryComponent(caseId)}',
      if (listingId != null) 'listingId=${Uri.encodeQueryComponent(listingId)}',
      'isPrimary=$isPrimary',
    ];
    final path = '/api/produce-images?${params.join('&')}';
    final json = await _api.uploadFile(path, bytes: bytes, filename: filename) as Map<String, dynamic>;
    final image = ProduceImage.fromApi(json);
    _upsert(image);
    notifyListeners();
    return image;
  }

  /// Re-runs verification on an already-uploaded image — the "try again"
  /// action shown after a SUSPICIOUS or VERIFICATION_FAILED result.
  Future<ProduceImage> reverify(String imageId) async {
    final json = await _api.post('/api/produce-images/$imageId/reverify') as Map<String, dynamic>;
    final image = ProduceImage.fromApi(json);
    _upsert(image);
    notifyListeners();
    return image;
  }

  Future<void> deleteImage(String imageId) async {
    await _api.delete('/api/produce-images/$imageId');
    _images.removeWhere((i) => i.id == imageId);
    notifyListeners();
  }

  void _upsert(ProduceImage updated) {
    final index = _images.indexWhere((i) => i.id == updated.id);
    if (index == -1) {
      _images.add(updated);
    } else {
      _images[index] = updated;
    }
  }
}
