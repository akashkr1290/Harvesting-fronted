import 'user_role.dart';
import '../utils/api_dates.dart';

class AppUser {
  final String id;
  final String name;
  final String mobile;
  final String email;
  final UserRole role;
  final String location;
  final String username;
  bool active;
  DateTime? lastActive;
  bool mustChangePassword;

  AppUser({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    required this.role,
    required this.location,
    required this.username,
    this.active = true,
    this.lastActive,
    this.mustChangePassword = true,
  });

  /// Parses UserResponse. Note there's no password field here — the
  /// backend only ever returns a plaintext temp password once, wrapped in
  /// CredentialResponse, right after creation or a reset (see UserService).
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      mobile: json['mobile'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: userRoleFromApi(json['role'] as String),
      location: json['location'] as String? ?? '',
      username: json['username'] as String,
      active: json['active'] as bool? ?? true,
      lastActive: parseApiInstantOrNull(json['lastActiveAt'] as String?),
      mustChangePassword: json['mustChangePassword'] as bool? ?? true,
    );
  }
}
