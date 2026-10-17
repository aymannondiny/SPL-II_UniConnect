import 'package:flutter/material.dart';

/// Shares the chosen appearance across navigation for the app's lifetime.
class ThemePreference extends InheritedNotifier<ValueNotifier<ThemeMode>> {
  const ThemePreference({
    required ValueNotifier<ThemeMode> controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static ValueNotifier<ThemeMode>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemePreference>()?.notifier;
}
