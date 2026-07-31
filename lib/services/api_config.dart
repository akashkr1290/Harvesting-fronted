/// Backend base URL. Override at build/run time with:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.50:4000
///
/// Defaults assume the Spring Boot backend is running locally on port 4000.
/// Note the Android emulator can't reach the host machine via "localhost" —
/// it needs the special alias 10.0.2.2 — so the default below picks that
/// automatically when running on Android. iOS simulator, web, and desktop
/// can all reach the host via plain localhost.
library;

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:4000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:4000';
    } catch (_) {
      // Platform.isAndroid throws on web, but kIsWeb already handled that
      // above — this catch is just a safety net for other odd targets.
    }
    return 'http://localhost:4000';
  }
}
