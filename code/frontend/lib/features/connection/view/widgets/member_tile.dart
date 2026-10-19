import 'package:flutter/material.dart';

import '../../model/connection_models.dart';

/// Search result whose actions wrap below the identity on narrow screens.
class MemberTile extends StatelessWidget {
  const MemberTile({
    required this.member,
    required this.onProfile,
    required this.action,
    super.key,
  });
  final MemberProfile member;
  final VoidCallback onProfile;
  final Widget action;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                child: Text(
                  member.name.trim().isEmpty
                      ? '?'
                      : member.name.characters.first.toUpperCase(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member.headline,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: onProfile,
                child: const Text('View profile'),
              ),
              action,
            ],
          ),
        ],
      ),
    ),
  );
}
