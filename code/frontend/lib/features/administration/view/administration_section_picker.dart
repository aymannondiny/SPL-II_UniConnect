import 'package:flutter/material.dart';

class AdministrationSectionPicker extends StatelessWidget {
  const AdministrationSectionPicker({
    required this.selected,
    required this.onChanged,
    required this.accountsEnabled,
    required this.reportsEnabled,
    super.key,
  });
  final int selected;
  final ValueChanged<int> onChanged;
  final bool accountsEnabled;
  final bool reportsEnabled;

  @override
  Widget build(BuildContext context) {
    final sections = <int, String>{
      0: 'Academic catalog',
      1: 'Club administration',
      2: 'Club requests',
      if (accountsEnabled) 3: 'Accounts',
      if (reportsEnabled) 4: 'Reports',
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return DropdownButtonFormField<int>(
            initialValue: selected,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Administration area'),
            items: [
              for (final section in sections.entries)
                DropdownMenuItem(
                  value: section.key,
                  child: Text(section.value),
                ),
            ],
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          );
        }
        return SegmentedButton<int>(
          segments: [
            for (final section in sections.entries)
              ButtonSegment(value: section.key, label: Text(section.value)),
          ],
          selected: {selected},
          onSelectionChanged: (value) => onChanged(value.first),
        );
      },
    );
  }
}
