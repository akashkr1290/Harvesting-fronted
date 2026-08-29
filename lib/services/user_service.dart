import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/app_user.dart';
import '../models/login_history_entry.dart';
import '../models/user_role.dart';

/// Returned once by createUser/resetPassword — the only two moments the
/// plaintext temp password ever exists client-side. Nothing stores it
/// after that; the admin has to read it off the screen (or share it) then.
class CredentialResult {
  final AppUser user;
  final String temporaryPassword;

  CredentialResult({required this.user, required this.temporaryPassword});
}

class UserService extends ChangeNotifier {
  final ApiClient _api;
  final List<AppUser> _users = [];
  bool _loading = false;

  UserService(this._api);

  List<AppUser> get users => List.unmodifiable(_users);
  bool get isLoading => _loading;

  Future<void> fetchUsers() async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _api.get('/api/users') as List<dynamic>;
      _users
        ..clear()
        ..addAll(res.map((j) => AppUser.fromJson(j as Map<String, dynamic>)));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<CredentialResult> createUser({
    required String name,
    required String mobile,
    required String email,
    required UserRole role,
    required String location,
  }) async {
    final res = await _api.post('/api/users', body: {
      'name': name,
      'mobile': mobile,
      'email': email,
      'role': role.apiValue,
      'location': location,
    }) as Map<String, dynamic>;

    final user = AppUser.fromJson(res['user'] as Map<String, dynamic>);
    _users.add(user);
    notifyListeners();
    return CredentialResult(user: user, temporaryPassword: res['temporaryPassword'] as String);
  }

  Future<void> toggleActive(AppUser user) async {
    final res = await _api.patch('/api/users/${user.id}/toggle-active') as Map<String, dynamic>;
    final updated = AppUser.fromJson(res);
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) _users[index] = updated;
    notifyListeners();
  }

  Future<CredentialResult> resetPassword(AppUser user) async {
    final res = await _api.post('/api/users/${user.id}/reset-password') as Map<String, dynamic>;
    final updated = AppUser.fromJson(res['user'] as Map<String, dynamic>);
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) _users[index] = updated;
    notifyListeners();
    return CredentialResult(user: updated, temporaryPassword: res['temporaryPassword'] as String);
  }

  Future<List<LoginHistoryEntry>> getLoginHistory(AppUser user) async {
    final res = await _api.get('/api/users/${user.id}/login-history') as List<dynamic>;
    return res.map((j) => LoginHistoryEntry.fromJson(j as Map<String, dynamic>)).toList();
  }
}
