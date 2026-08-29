import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/offer.dart';
import '../models/market_order.dart';

/// Buyer offer submission/withdrawal and farmer offer accept/reject.
/// Accepting returns a MarketOrder (the backend creates it in the same
/// transaction), which the caller can hand straight to OrderService's
/// cache rather than doing a separate fetch.
class OfferService extends ChangeNotifier {
  final ApiClient _api;
  OfferService(this._api);

  bool _loading = false;
  bool get isLoading => _loading;

  List<Offer> _myOffers = [];
  List<Offer> get myOffers => List.unmodifiable(_myOffers);

  List<Offer> _received = [];
  List<Offer> get received => List.unmodifiable(_received);

  Future<void> fetchMyOffers() async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _api.get('/api/marketplace/offers/mine') as List;
      _myOffers = res.map((e) => Offer.fromJson(e as Map<String, dynamic>)).toList();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Every offer across every listing the logged-in farmer/FPO owns.
  Future<void> fetchReceived() async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _api.get('/api/marketplace/offers/received') as List;
      _received = res.map((e) => Offer.fromJson(e as Map<String, dynamic>)).toList();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<List<Offer>> forListing(String listingId) async {
    final res = await _api.get('/api/marketplace/listings/$listingId/offers') as List;
    return res.map((e) => Offer.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Offer> submit(String listingId, {required double quantity, required double pricePerUnit, String? message}) async {
    final res = await _api.post('/api/marketplace/listings/$listingId/offers', body: {
      'quantity': quantity,
      'pricePerUnit': pricePerUnit,
      'message': message,
    }) as Map<String, dynamic>;
    await fetchMyOffers();
    return Offer.fromJson(res);
  }

  Future<Offer> withdraw(String offerId) async {
    final res = await _api.post('/api/marketplace/offers/$offerId/withdraw') as Map<String, dynamic>;
    await fetchMyOffers();
    return Offer.fromJson(res);
  }

  Future<MarketOrder> accept(String offerId) async {
    final res = await _api.post('/api/marketplace/offers/$offerId/accept') as Map<String, dynamic>;
    await fetchReceived();
    return MarketOrder.fromJson(res);
  }

  Future<Offer> reject(String offerId) async {
    final res = await _api.post('/api/marketplace/offers/$offerId/reject') as Map<String, dynamic>;
    await fetchReceived();
    return Offer.fromJson(res);
  }
}
