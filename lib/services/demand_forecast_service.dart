import 'package:flutter/foundation.dart';
import '../models/demand_prediction.dart';
import 'api_client.dart';

/// Part A (Flutter side). Generating a forecast is ADMIN/PLANNING-only on
/// the backend; reading one is open to any authenticated user — this
/// service doesn't duplicate either check, it just surfaces whatever the
/// API returns (including a 403 if a non-planning role tries to generate).
class DemandForecastService extends ChangeNotifier {
  final ApiClient _api;

  DemandForecastService(this._api);

  bool _isLoading = false;
  String? _lastError;
  List<DemandPrediction> _overview = [];
  DemandPrediction? _selected;
  List<DemandPrediction> _history = [];

  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  List<DemandPrediction> get overview => List.unmodifiable(_overview);
  DemandPrediction? get selected => _selected;
  List<DemandPrediction> get history => List.unmodifiable(_history);

  /// Latest forecast for every crop/location that has one — feeds the overview list.
  Future<void> fetchOverview() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      final res = await _api.get('/api/demand') as List<dynamic>;
      _overview = res.map((j) => DemandPrediction.fromJson(j as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      _lastError = e.message;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generate(String cropType, String location) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      final res = await _api.post('/api/demand/predict', body: {
        'cropType': cropType,
        'location': location,
      }) as Map<String, dynamic>;
      _selected = DemandPrediction.fromJson(res);
    } on ApiException catch (e) {
      _lastError = e.message;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchLatest(String cropType, String location) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      final res = await _api.get('/api/demand/latest', query: {
        'cropType': cropType,
        'location': location,
      }) as Map<String, dynamic>;
      _selected = DemandPrediction.fromJson(res);
    } on ApiException catch (e) {
      _lastError = e.message;
      _selected = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistory(String cropType, String location) async {
    try {
      final res = await _api.get('/api/demand/history', query: {
        'cropType': cropType,
        'location': location,
      }) as List<dynamic>;
      _history = res.map((j) => DemandPrediction.fromJson(j as Map<String, dynamic>)).toList();
      notifyListeners();
    } on ApiException {
      _history = [];
      notifyListeners();
      rethrow;
    }
  }
}
