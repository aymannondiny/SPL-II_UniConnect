import 'package:flutter/material.dart';

import '../../model/club.dart';

class ClubTile extends StatelessWidget {
  const ClubTile({
    required this.club,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final Club club;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      selected: selected,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: .12)
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: selected
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: .18),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.groups_outlined,
                  color: theme.colorScheme.primary,
                  size: 30,
                ),
                const SizedBox(height: 16),
                Text(club.name, style: theme.textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  club.category,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  club.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Text(
                  selected ? 'Viewing club' : 'View club →',
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
