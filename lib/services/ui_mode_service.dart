import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_role.dart';

/// Simple = big pictures, voice, one task per screen (default for farmers and FPOs).
/// Detailed = dense tables and filters (default for buyers and company staff).
/// Same data and API in both; anyone can switch at any time.
enum UiMode { simple, detailed }

class UiModeService extends ChangeNotifier {
  static const _key = 'harvestflow.uiMode';
  UiMode? _chosen;

  /// The user's own choice, if they made one; otherwise a default for their role.
  UiMode modeFor(UserRole? role) {
    if (_chosen != null) return _chosen!;
    if (role == UserRole.farmer || role == UserRole.fpo || role == UserRole.consumer) return UiMode.simple;
    return UiMode.detailed;
  }

  bool isSimple(UserRole? role) => modeFor(role) == UiMode.simple;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = p.getString(_key);
      if (v != null) _chosen = v == 'simple' ? UiMode.simple : UiMode.detailed;
    } catch (_) {
      // No stored preference: role default is used.
    }
    notifyListeners();
  }

  Future<void> setMode(UiMode mode) async {
    _chosen = mode;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, mode.name);
    } catch (_) {}
  }
}
