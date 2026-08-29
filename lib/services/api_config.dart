/// Backend base URL — **always set explicitly at build/run time**:
///
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.50:4000
///   flutter build web --dart-define=API_BASE_URL=https://api.yourdomain.com
///   flutter build apk --release --dart-define=API_BASE_URL=https://api.yourdomain.com
///
/// There is deliberately no hardcoded production IP/domain here anymore —
/// a previous version of this file defaulted to a specific EC2 instance's
/// IP address over plain HTTP, meaning every deploy silently pointed at
/// that one address until someone remembered to edit and redeploy this
/// file. See amplify.yml for how the web build now gets this value from
/// an Amplify Console environment variable instead.
///
/// The only fallback below is localhost, which is a *local development*
/// convenience, not a production default: Android emulator can't reach
/// the host machine via "localhost" (it needs the special alias
/// 10.0.2.2), so the fallback picks that automatically on Android;
/// iOS simulator, web, and desktop can all reach the host via plain
/// localhost. Any real deployment (web, APK, etc.) must pass
/// --dart-define=API_BASE_URL explicitly — see the backend README for
/// what to put there once you have a real domain.
library;

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;

    // Local-dev-only fallback — never used once --dart-define is passed.
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:4000';
    }
    return 'http://localhost:4000';
  }
}
