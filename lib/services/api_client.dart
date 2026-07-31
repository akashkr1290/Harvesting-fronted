import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Mirrors the backend's ApiError record (timestamp, status, error, message,
/// details) so every service can show the same message the API returned —
/// e.g. "Case is currently PLANNED; this action requires RATE_UPDATED"
/// instead of a generic "request failed".
class ApiException implements Exception {
  final int statusCode;
  final String error;
  final String message;
  final List<String> details;

  ApiException({
    required this.statusCode,
    required this.error,
    required this.message,
    this.details = const [],
  });

  /// 403 = wrong role for this action; 409 = case isn't in the expected
  /// status. Both come from CaseService.assertTransition on the backend —
  /// screens can check these to decide whether to show a "someone else
  /// already moved this case" message vs a generic error.
  bool get isForbidden => statusCode == 403;
  bool get isConflict => statusCode == 409;

  @override
  String toString() => message;
}

/// One shared instance is created in main.dart and injected into every
/// service, so the JWT set by AuthService.login() is immediately visible
/// to MasterDataService/UserService/CaseService without any extra wiring.
class ApiClient {
  final String baseUrl;
  String? _token;

  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  void setToken(String? token) => _token = token;
  bool get hasToken => _token != null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    Map<String, String>? cleanQuery;
    if (query != null) {
      cleanQuery = {};
      query.forEach((key, value) {
        if (value != null) cleanQuery![key] = value.toString();
      });
    }
    return Uri.parse('$baseUrl$path').replace(
      queryParameters: (cleanQuery == null || cleanQuery.isEmpty) ? null : cleanQuery,
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final res = await http.get(_uri(path, query), headers: _headers).timeout(_timeout);
    return _handle(res);
  }

  /// For binary responses (currently: the generated PDF documents) rather
  /// than JSON. Sends an Accept header matching what DocumentController
  /// actually produces — sending "application/json" (the default _headers)
  /// against an endpoint that only produces "application/pdf" risks a 406
  /// from Spring's content negotiation.
  Future<List<int>> getBytes(String path) async {
    final headers = <String, String>{
      'Accept': 'application/pdf, */*',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    final res = await http.get(_uri(path), headers: headers).timeout(_timeout);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.bodyBytes;
    }
    throw _parseError(res);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final res = await http
        .post(_uri(path), headers: _headers, body: body == null ? null : jsonEncode(body))
        .timeout(_timeout);
    return _handle(res);
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final res = await http
        .put(_uri(path), headers: _headers, body: body == null ? null : jsonEncode(body))
        .timeout(_timeout);
    return _handle(res);
  }

  Future<dynamic> patch(String path, {Object? body}) async {
    final res = await http
        .patch(_uri(path), headers: _headers, body: body == null ? null : jsonEncode(body))
        .timeout(_timeout);
    return _handle(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(_uri(path), headers: _headers).timeout(_timeout);
    return _handle(res);
  }

  static const _timeout = Duration(seconds: 15);

  dynamic _handle(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    throw _parseError(res);
  }

  ApiException _parseError(http.Response res) {
    try {
      final parsed = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return ApiException(
        statusCode: res.statusCode,
        error: parsed['error'] as String? ?? 'Error',
        message: parsed['message'] as String? ?? 'Request failed (${res.statusCode})',
        details: (parsed['details'] as List?)?.cast<String>() ?? const [],
      );
    } catch (_) {
      return ApiException(
        statusCode: res.statusCode,
        error: 'Error',
        message: 'Request failed (${res.statusCode})',
      );
    }
  }
}
