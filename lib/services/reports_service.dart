import 'package:flutter/foundation.dart';
import '../models/reports_summary.dart';
import 'api_client.dart';

class ReportsService extends ChangeNotifier {
  final ApiClient _api;

  ReportsService(this._api);

  ReportsSummary? _summary;
  bool _isLoading = false;
  String? _lastError;

  ReportsSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  Future<void> fetchSummary() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      final res = await _api.get('/api/reports/summary');
      _summary = ReportsSummary.fromJson(res as Map<String, dynamic>);
    } on ApiException catch (e) {
      _lastError = e.message;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
