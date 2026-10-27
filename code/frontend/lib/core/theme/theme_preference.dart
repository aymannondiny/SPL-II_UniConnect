import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppearanceMode { light, dark, engineering }

extension AppearanceModeLabel on AppearanceMode {
  String get label => switch (this) {
    AppearanceMode.light => 'Light Mode',
    AppearanceMode.dark => 'Dark Mode',
    AppearanceMode.engineering => 'Engineering Mode',
  };

  IconData get icon => switch (this) {
    AppearanceMode.light => Icons.light_mode_outlined,
    AppearanceMode.dark => Icons.dark_mode_outlined,
    AppearanceMode.engineering => Icons.memory_outlined,
  };
}

abstract interface class AppearanceStore {
  Future<String?> read();
  Future<void> write(String value);
}

class SharedPreferencesAppearanceStore implements AppearanceStore {
  static const key = 'appearance_mode';

  @override
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> write(String value) async =>
      (await SharedPreferences.getInstance()).setString(key, value);
}

class AppearanceController extends ValueNotifier<AppearanceMode> {
  AppearanceController({AppearanceStore? store})
    : _store = store ?? SharedPreferencesAppearanceStore(),
      super(AppearanceMode.dark);

  final AppearanceStore _store;

  Future<void> restore() async {
    final stored = await _store.read();
    final restored = AppearanceMode.values.where((mode) => mode.name == stored);
    if (restored.isNotEmpty) super.value = restored.first;
  }

  @override
  set value(AppearanceMode next) {
    if (next == value) return;
    super.value = next;
    unawaited(_store.write(next.name));
  }
}

/// Shares and persists the chosen appearance across every application route.
class ThemePreference extends InheritedNotifier<AppearanceController> {
  const ThemePreference({
    required AppearanceController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppearanceController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemePreference>()?.notifier;
}
