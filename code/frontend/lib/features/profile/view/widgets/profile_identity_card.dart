import 'package:flutter/material.dart';

/// Owner identity summary; initials remain available without photo storage.
class ProfileIdentityCard extends StatelessWidget {
  const ProfileIdentityCard({
    required this.name,
    required this.role,
    this.programme,
    super.key,
  });
  final String name;
  final String role;
  final String? programme;
  String get _initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((s) => s.isNotEmpty)
      .take(2)
      .map((s) => s.characters.first.toUpperCase())
      .join();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${role == 'ALUMNI' ? 'Alumni' : 'Student'}${programme == null ? '' : ' · $programme'}',
                ),
                const SizedBox(height: 12),
                const Chip(
                  avatar: Icon(Icons.verified_outlined, size: 16),
                  label: Text('Verified university email'),
                ),
              ],
            );
            final avatar = CircleAvatar(
              radius: 32,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: .12),
              foregroundColor: theme.colorScheme.primary,
              child: Text(
                _initials,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            );
            return constraints.maxWidth < 380
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [avatar, const SizedBox(height: 16), details],
                  )
                : Row(
                    children: [
                      avatar,
                      const SizedBox(width: 20),
                      Expanded(child: details),
                    ],
                  );
          },
        ),
      ),
    );
  }
}
