import 'package:flutter/foundation.dart';
import '../models/route_optimization.dart';
import 'api_client.dart';

/// Part B + C (Flutter side). Triggering an optimization is
/// ADMIN/PICKUP_PERSON/TRANSPORT_PERSON-only on the backend; reading a
/// result is open to any authenticated user.
class RouteOptimizationService extends ChangeNotifier {
  final ApiClient _api;

  RouteOptimizationService(this._api);

  bool _isLoading = false;
  String? _lastError;
  RouteOptimizationResult? _lastResult;
  List<RouteOptimizationResult> _caseHistory = [];
  List<DeliveryVehicle> _vehicles = [];

  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  RouteOptimizationResult? get lastResult => _lastResult;
  List<RouteOptimizationResult> get caseHistory => List.unmodifiable(_caseHistory);
  List<DeliveryVehicle> get vehicles => List.unmodifiable(_vehicles);

  Future<void> fetchVehicles({bool activeOnly = true}) async {
    final res = await _api.get('/api/logistics/vehicles', query: {'activeOnly': activeOnly}) as List<dynamic>;
    _vehicles = res.map((j) => DeliveryVehicle.fromJson(j as Map<String, dynamic>)).toList();
    notifyListeners();
  }

  Future<RouteOptimizationResult> optimize({
    String? caseId,
    String? vehicleId,
    required RouteStopInput pickup,
    required List<RouteStopInput> deliveries,
    required double totalQuantityKg,
    double? costPerKm,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      final res = await _api.post('/api/logistics/routes/optimize', body: {
        'caseId': caseId,
        'vehicleId': vehicleId,
        'pickup': pickup.toJson(),
        'deliveries': deliveries.map((d) => d.toJson()).toList(),
        'totalQuantityKg': totalQuantityKg,
        'costPerKm': costPerKm,
      }) as Map<String, dynamic>;
      _lastResult = RouteOptimizationResult.fromJson(res);
      return _lastResult!;
    } on ApiException catch (e) {
      _lastError = e.message;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchByCase(String caseId) async {
    final res = await _api.get('/api/logistics/routes/by-case/$caseId') as List<dynamic>;
    _caseHistory = res.map((j) => RouteOptimizationResult.fromJson(j as Map<String, dynamic>)).toList();
    notifyListeners();
  }
}
