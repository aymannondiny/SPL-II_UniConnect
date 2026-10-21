import 'package:flutter/material.dart';
import 'package:uniconnect/features/mentorship/model/mentor_summary.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentorship_status_badge.dart';

class MentorCard extends StatelessWidget {
  const MentorCard({required this.mentor, required this.onTap, super.key});

  final MentorSummary mentor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    String subtitle = mentor.role == 'ALUMNI' ? 'Alumni' : 'Student';
    if (mentor.departmentName != null) {
      subtitle += ' • ${mentor.departmentName}';
    }
    if (mentor.yearOfStudy != null) {
      subtitle += ' • Year ${mentor.yearOfStudy}';
    } else if (mentor.graduationYear != null) {
      subtitle += ' • Class of ${mentor.graduationYear}';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: colors.primaryContainer,
                    backgroundImage: mentor.profilePhotoUrl != null
                        ? NetworkImage(mentor.profilePhotoUrl!)
                        : null,
                    child: mentor.profilePhotoUrl == null
                        ? Text(
                            mentor.fullName.isNotEmpty
                                ? mentor.fullName[0].toUpperCase()
                                : 'M',
                            style: TextStyle(
                              color: colors.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mentor.fullName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  MentorshipStatusBadge.mentorStatus(mentor.status, colors),
                ],
              ),
              if (mentor.expertiseTopics.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: mentor.expertiseTopics.take(4).map((topic) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(
                          alpha: 0.6,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        topic,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('View Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
