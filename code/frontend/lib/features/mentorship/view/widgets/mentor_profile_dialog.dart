import 'package:flutter/material.dart';
import 'package:uniconnect/features/mentorship/data/mentorship_repository.dart';
import 'package:uniconnect/features/mentorship/model/mentor_profile.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentorship_status_badge.dart';

class MentorProfileDialog extends StatefulWidget {
  const MentorProfileDialog({
    required this.mentorProfileId,
    required this.repository,
    super.key,
  });

  final int mentorProfileId;
  final MentorshipRepository repository;

  static Future<void> show(
    BuildContext context, {
    required int mentorProfileId,
    required MentorshipRepository repository,
  }) {
    return showDialog(
      context: context,
      builder: (_) => MentorProfileDialog(
        mentorProfileId: mentorProfileId,
        repository: repository,
      ),
    );
  }

  @override
  State<MentorProfileDialog> createState() => _MentorProfileDialogState();
}

class _MentorProfileDialogState extends State<MentorProfileDialog> {
  MentorProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.repository.getMentorProfile(
        widget.mentorProfileId,
      );
      if (mounted) {
        setState(() {
          _profile = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load mentor profile details.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: colors.error),
                    const SizedBox(height: 12),
                    Text(_error!),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ],
                )
              : _content(theme, colors),
        ),
      ),
    );
  }

  Widget _content(ThemeData theme, ColorScheme colors) {
    final profile = _profile!;
    String subtitle = profile.role == 'ALUMNI' ? 'Alumni' : 'Student';
    if (profile.departmentName != null) {
      subtitle += ' • ${profile.departmentName}';
    }
    if (profile.yearOfStudy != null) {
      subtitle += ' • Year ${profile.yearOfStudy}';
    } else if (profile.graduationYear != null) {
      subtitle += ' • Class of ${profile.graduationYear}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: colors.primaryContainer,
              backgroundImage: profile.profilePhotoUrl != null
                  ? NetworkImage(profile.profilePhotoUrl!)
                  : null,
              child: profile.profilePhotoUrl == null
                  ? Text(
                      profile.fullName.isNotEmpty
                          ? profile.fullName[0].toUpperCase()
                          : 'M',
                      style: TextStyle(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        MentorshipStatusBadge.mentorStatus(profile.status, colors),
        const SizedBox(height: 16),
        const Divider(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Mentorship',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(profile.mentoringBio, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 18),
                Text(
                  'Expertise Areas',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (profile.expertise.isEmpty)
                  Text(
                    'No specific expertise topics listed.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  )
                else
                  ...profile.expertise.map((exp) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check, size: 18, color: colors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exp.topic,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (exp.description != null &&
                                    exp.description!.isNotEmpty)
                                  Text(
                                    exp.description!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ],
    );
  }
}
