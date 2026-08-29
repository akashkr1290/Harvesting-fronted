import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/market_order.dart';

/// Order history (seller and buyer both call the same endpoint — the
/// backend returns whichever orders this user is a party to) and the
/// farmer/FPO earnings summary.
class OrderService extends ChangeNotifier {
  final ApiClient _api;
  OrderService(this._api);

  bool _loading = false;
  bool get isLoading => _loading;

  List<MarketOrder> _orders = [];
  List<MarketOrder> get orders => List.unmodifiable(_orders);

  EarningsSummary? _earnings;
  EarningsSummary? get earnings => _earnings;

  Future<void> fetchOrders() async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _api.get('/api/marketplace/orders') as List;
      _orders = res.map((e) => MarketOrder.fromJson(e as Map<String, dynamic>)).toList();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<MarketOrder> getOrder(String id) async {
    final res = await _api.get('/api/marketplace/orders/$id') as Map<String, dynamic>;
    return MarketOrder.fromJson(res);
  }

  /// Phase 5: confirms delivery on a CONFIRMED order and releases the
  /// simulated payment (OrderService.completeDeliveryAndSettle on the
  /// backend) — the "Delivery completed -> payment released -> farmer
  /// earnings" step of the master spec's demo story. Either party may
  /// call this.
  Future<MarketOrder> completeDelivery(String id) async {
    final res = await _api.post('/api/marketplace/orders/$id/complete-delivery') as Map<String, dynamic>;
    final order = MarketOrder.fromJson(res);
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index != -1) _orders[index] = order;
    notifyListeners();
    return order;
  }

  Future<void> fetchEarnings() async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _api.get('/api/marketplace/earnings') as Map<String, dynamic>;
      _earnings = EarningsSummary.fromJson(res);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
