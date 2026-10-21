import 'package:flutter/material.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enums.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_slot_summary.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentorship_status_badge.dart';

class HostSlotCard extends StatelessWidget {
  const HostSlotCard({
    required this.slot,
    required this.onTap,
    required this.onViewAttendees,
    required this.onEdit,
    required this.onClose,
    required this.onCancel,
    super.key,
  });

  final MentorshipSlotSummary slot;
  final VoidCallback onTap;
  final VoidCallback onViewAttendees;
  final VoidCallback onEdit;
  final VoidCallback onClose;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final scheduleLabel =
        '${slot.scheduleType.label} • ${slot.startDate} at ${slot.startTime.length >= 5 ? slot.startTime.substring(0, 5) : slot.startTime}';
    final isActive =
        slot.status == SlotStatus.open || slot.status == SlotStatus.full;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                MentorshipStatusBadge.slotStatus(slot.status, colors),
                MentorshipStatusBadge.mode(slot.mode, colors),
                Text(
                  '${slot.currentMenteeCount}/${slot.capacity} Enrolled',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
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
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    scheduleLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onViewAttendees,
                  icon: const Icon(Icons.people_outline, size: 16),
                  label: const Text('Attendees'),
                ),
                if (isActive) ...[
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Close Session Enrollment?'),
                          content: Text(
                            'Stop accepting new mentees for "${slot.topic}"? Existing enrolled mentees remain active.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Keep Open'),
                            ),
                            FilledButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                onClose();
                              },
                              child: const Text('Close Enrollment'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Close'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Cancel Session?'),
                          content: Text(
                            'Are you sure you want to cancel "${slot.topic}"? All enrolled mentees will be notified immediately.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('No'),
                            ),
                            FilledButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                onCancel();
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: colors.error,
                                foregroundColor: colors.onError,
                              ),
                              child: const Text('Cancel Session'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.error,
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
