import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const chatPerformanceLogging = bool.fromEnvironment(
    'CHAT_PERFORMANCE_LOGGING',
  );

  static String get apiBaseUrl => resolveApiBaseUrl(
    override: const String.fromEnvironment('API_BASE_URL'),
    isWeb: kIsWeb,
    platform: defaultTargetPlatform,
  );

  /// Emulator loopback reaches the development host, not the Android device.
  /// Physical devices and deployments must supply their reachable API URL.
  static String resolveApiBaseUrl({
    required String override,
    required bool isWeb,
    required TargetPlatform platform,
  }) {
    if (override.isNotEmpty) return override;
    if (!isWeb && platform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }
}
