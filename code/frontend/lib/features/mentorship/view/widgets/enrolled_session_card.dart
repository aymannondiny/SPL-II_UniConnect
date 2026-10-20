import 'package:flutter/material.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enums.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_slot_summary.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentorship_status_badge.dart';

class EnrolledSessionCard extends StatelessWidget {
  const EnrolledSessionCard({
    required this.slot,
    required this.onTap,
    required this.onLeave,
    super.key,
  });

  final MentorshipSlotSummary slot;
  final VoidCallback onTap;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final scheduleLabel = '${slot.scheduleType.label} • ${slot.startDate} at ${slot.startTime.length >= 5 ? slot.startTime.substring(0, 5) : slot.startTime}';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MentorshipStatusBadge(
                  label: 'Enrolled',
                  backgroundColor: Colors.green.shade50,
                  textColor: Colors.green.shade800,
                  icon: Icons.check_circle,
                ),
                const SizedBox(width: 8),
                MentorshipStatusBadge.mode(slot.mode, colors),
                const Spacer(),
                MentorshipStatusBadge.slotStatus(slot.status, colors),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              slot.topic,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Mentor: ${slot.mentorName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: colors.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  scheduleLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (slot.mode == SlotMode.online && slot.meetingLink != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.videocam, size: 16, color: colors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      slot.meetingLink!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.primary,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (slot.mode == SlotMode.inPerson && slot.location != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: colors.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      slot.location!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onTap,
                  child: const Text('View Details'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Leave Mentorship Session?'),
                        content: Text('Are you sure you want to release your spot in "${slot.topic}"? Your mentor will be notified.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Keep Spot'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              onLeave();
                            },
                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Leave Session'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
                  child: const Text('Leave'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
