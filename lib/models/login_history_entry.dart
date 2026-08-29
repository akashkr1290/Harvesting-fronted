import '../utils/api_dates.dart';

class LoginHistoryEntry {
  final String username;
  final DateTime loggedInAt;
  final String? ipAddress;
  final bool success;
  final String? failureReason;

  LoginHistoryEntry({
    required this.username,
    required this.loggedInAt,
    this.ipAddress,
    required this.success,
    this.failureReason,
  });

  factory LoginHistoryEntry.fromJson(Map<String, dynamic> json) {
    return LoginHistoryEntry(
      username: json['username'] as String,
      loggedInAt: parseApiInstant(json['loggedInAt'] as String),
      ipAddress: json['ipAddress'] as String?,
      success: json['success'] as bool,
      failureReason: json['failureReason'] as String?,
    );
  }
}
