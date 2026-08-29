import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/produce_listing.dart';
import '../utils/api_dates.dart';

/// Farmer/FPO listing management + buyer marketplace search. Kept as two
/// separate in-memory caches (own listings vs marketplace search results)
/// rather than one merged list — a farmer's drafts should never leak into
/// a buyer's search results just because both happen to be cached
/// locally, so there's no shared list to accidentally filter wrong.
class MarketplaceService extends ChangeNotifier {
  final ApiClient _api;
  MarketplaceService(this._api);

  bool _loading = false;
  bool get isLoading => _loading;

  List<ProduceListingSummary> _myListings = [];
  List<ProduceListingSummary> get myListings => List.unmodifiable(_myListings);

  List<ProduceListingSummary> _marketplaceResults = [];
  List<ProduceListingSummary> get marketplaceResults => List.unmodifiable(_marketplaceResults);

  Future<void> fetchMyListings() async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _api.get('/api/marketplace/listings/mine') as List;
      _myListings = res.map((e) => ProduceListingSummary.fromJson(e as Map<String, dynamic>)).toList();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> searchMarketplace({
    String? query,
    String? location,
    String? cropName,
    double? minPrice,
    double? maxPrice,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _api.get('/api/marketplace/listings', query: {
        'q': query,
        'location': location,
        'cropName': cropName,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
      }) as List;
      _marketplaceResults = res.map((e) => ProduceListingSummary.fromJson(e as Map<String, dynamic>)).toList();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<ProduceListingDetail> getListing(String id) async {
    final res = await _api.get('/api/marketplace/listings/$id') as Map<String, dynamic>;
    return ProduceListingDetail.fromJson(res);
  }

  Future<ProduceListingDetail> createListing({
    required String cropName,
    required double quantity,
    required String unit,
    String? quality,
    required DateTime harvestDate,
    required String location,
    required double expectedPricePerUnit,
    String? description,
  }) async {
    final res = await _api.post('/api/marketplace/listings', body: {
      'cropName': cropName,
      'quantity': quantity,
      'unit': unit,
      'quality': quality,
      'harvestDate': formatApiDate(harvestDate),
      'location': location,
      'expectedPricePerUnit': expectedPricePerUnit,
      'description': description,
    }) as Map<String, dynamic>;
    await fetchMyListings();
    return ProduceListingDetail.fromJson(res);
  }

  Future<ProduceListingDetail> updateListing(
    String id, {
    required String cropName,
    required double quantity,
    required String unit,
    String? quality,
    required DateTime harvestDate,
    required String location,
    required double expectedPricePerUnit,
    String? description,
  }) async {
    final res = await _api.put('/api/marketplace/listings/$id', body: {
      'cropName': cropName,
      'quantity': quantity,
      'unit': unit,
      'quality': quality,
      'harvestDate': formatApiDate(harvestDate),
      'location': location,
      'expectedPricePerUnit': expectedPricePerUnit,
      'description': description,
    }) as Map<String, dynamic>;
    await fetchMyListings();
    return ProduceListingDetail.fromJson(res);
  }

  Future<ProduceListingDetail> publish(String id) async {
    final res = await _api.post('/api/marketplace/listings/$id/publish') as Map<String, dynamic>;
    await fetchMyListings();
    return ProduceListingDetail.fromJson(res);
  }

  Future<ProduceListingDetail> close(String id) async {
    final res = await _api.post('/api/marketplace/listings/$id/close') as Map<String, dynamic>;
    await fetchMyListings();
    return ProduceListingDetail.fromJson(res);
  }

  Future<ProduceListingDetail> addImages(String id, List<String> imageUrls) async {
    final res = await _api.post('/api/marketplace/listings/$id/images', body: {
      'imageUrls': imageUrls,
    }) as Map<String, dynamic>;
    return ProduceListingDetail.fromJson(res);
  }
}
