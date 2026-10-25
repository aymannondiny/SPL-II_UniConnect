import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/config/app_config.dart';

void main() {
  test('Android emulator reaches the host API', () {
    expect(
      AppConfig.resolveApiBaseUrl(
        override: '',
        isWeb: false,
        platform: TargetPlatform.android,
      ),
      'http://10.0.2.2:8080',
    );
  });

  test('Android browser still uses the web API default', () {
    expect(
      AppConfig.resolveApiBaseUrl(
        override: '',
        isWeb: true,
        platform: TargetPlatform.android,
      ),
      'http://localhost:8080',
    );
  });

  for (final platform in TargetPlatform.values) {
    test('explicit deployment URL wins on $platform', () {
      expect(
        AppConfig.resolveApiBaseUrl(
          override: 'https://api.example.edu',
          isWeb: false,
          platform: platform,
        ),
        'https://api.example.edu',
      );
    });
  }
}
