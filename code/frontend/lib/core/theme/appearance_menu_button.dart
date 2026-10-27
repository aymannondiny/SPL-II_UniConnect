import 'package:flutter/material.dart';
import 'package:uniconnect/core/theme/theme_preference.dart';

class AppearanceMenuButton extends StatelessWidget {
  const AppearanceMenuButton({
    this.compact = false,
    this.mode,
    this.onSelected,
    super.key,
  });

  final bool compact;
  final AppearanceMode? mode;
  final ValueChanged<AppearanceMode>? onSelected;

  @override
  Widget build(BuildContext context) {
    final controller = ThemePreference.maybeOf(context);
    final current = mode ?? controller?.value ?? AppearanceMode.dark;
    return PopupMenuButton<AppearanceMode>(
      key: const Key('appearance-menu'),
      tooltip: 'Appearance: ${current.label}',
      initialValue: current,
      onSelected:
          onSelected ??
          (controller == null ? null : (mode) => controller.value = mode),
      icon: Icon(current.icon, size: compact ? 20 : 22),
      itemBuilder: (context) => [
        for (final mode in AppearanceMode.values)
          PopupMenuItem(
            value: mode,
            child: Row(
              children: [
                Icon(mode.icon, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(mode.label)),
                if (mode == current) const Icon(Icons.check, size: 18),
              ],
            ),
          ),
      ],
    );
  }
}
