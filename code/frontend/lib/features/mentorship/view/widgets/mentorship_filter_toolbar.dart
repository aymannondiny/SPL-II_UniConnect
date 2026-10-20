import 'package:flutter/material.dart';

class MentorshipFilterToolbar extends StatelessWidget {
  const MentorshipFilterToolbar({
    required this.searchController,
    required this.onSearchChanged,
    this.selectedYear,
    this.onYearChanged,
    this.onClear,
    this.hintText = 'Search mentors or topics...',
    super.key,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final int? selectedYear;
  final ValueChanged<int?>? onYearChanged;
  final VoidCallback? onClear;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 260,
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: hintText,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          if (onYearChanged != null)
            SizedBox(
              width: 140,
              child: DropdownButtonFormField<int?>(
                initialValue: selectedYear,
                decoration: InputDecoration(
                  labelText: 'Study Year',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Years')),
                  DropdownMenuItem(value: 2, child: Text('Year 2')),
                  DropdownMenuItem(value: 3, child: Text('Year 3')),
                  DropdownMenuItem(value: 4, child: Text('Year 4')),
                ],
                onChanged: onYearChanged,
              ),
            ),
          if (onClear != null)
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset'),
            ),
        ],
      ),
    );
  }
}
