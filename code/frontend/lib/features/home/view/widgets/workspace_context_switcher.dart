import 'package:flutter/material.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/home/controller/workspace_context_controller.dart';

class WorkspaceContextSwitcher extends StatelessWidget {
  const WorkspaceContextSwitcher({
    required this.controller,
    required this.onSelect,
    this.disabled = false,
    super.key,
  });

  final WorkspaceContextController controller;
  final ValueChanged<String> onSelect;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    if (EngineeringTheme.active(context)) {
      return DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          key: ValueKey(controller.selected.key),
          value:
              controller.available.any(
                (item) => item.key == controller.selected.key,
              )
              ? controller.selected.key
              : null,
          isExpanded: true,
          icon: controller.busy
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.expand_more, size: 20),
          hint: const Text('Personal workspace'),
          items: [
            for (final item in controller.available)
              DropdownMenuItem(
                value: item.key,
                child: Text(item.label, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: disabled || controller.busy
              ? null
              : (key) {
                  if (key != null) onSelect(key);
                },
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            key: ValueKey(controller.selected.key),
            initialValue:
                controller.available.any(
                  (item) => item.key == controller.selected.key,
                )
                ? controller.selected.key
                : null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Workspace',
              prefixIcon: const Icon(Icons.workspaces_outline),
              suffixIcon: IconButton(
                tooltip: 'Refresh workspaces',
                onPressed: disabled || controller.busy ? null : controller.load,
                icon: const Icon(Icons.refresh),
              ),
            ),
            hint: Text(
              controller.busy ? 'Loading workspaces…' : 'Personal workspace',
            ),
            items: [
              for (final item in controller.available)
                DropdownMenuItem(
                  value: item.key,
                  child: Text(item.label, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: disabled || controller.busy
                ? null
                : (key) {
                    if (key != null) onSelect(key);
                  },
          ),
          if (controller.busy) const LinearProgressIndicator(minHeight: 2),
          if (controller.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                controller.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}
