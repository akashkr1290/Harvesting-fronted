import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/user_role.dart';

/// Real auth against POST /api/auth/login. Holds the JWT and pushes it
/// into the shared ApiClient so every other service's requests are
/// authenticated automatically — nothing else needs to know a token exists.
class AuthService extends ChangeNotifier {
  final ApiClient _api;

  AuthService(this._api);

  String? _userId;
  String? _username;
  String? _name;
  UserRole? _role;
  bool _mustChangePassword = false;
  bool _loading = false;

  bool get isLoggedIn => _username != null && _role != null;
  bool get isLoading => _loading;
  String? get userId => _userId;
  String? get username => _username;
  String? get name => _name;
  UserRole? get role => _role;
  bool get mustChangePassword => _mustChangePassword;

  Future<void> login(String username, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _api.post('/api/auth/login', body: {
        'username': username,
        'password': password,
      }) as Map<String, dynamic>;

      _api.setToken(res['token'] as String);
      _userId = res['userId'] as String;
      _username = res['username'] as String;
      _name = res['name'] as String;
      _role = userRoleFromApi(res['role'] as String);
      _mustChangePassword = res['mustChangePassword'] as bool? ?? false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _api.post('/api/auth/change-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    _mustChangePassword = false;
    notifyListeners();
  }

  void logout() {
    _api.setToken(null);
    _userId = null;
    _username = null;
    _name = null;
    _role = null;
    _mustChangePassword = false;
    notifyListeners();
  }
}
