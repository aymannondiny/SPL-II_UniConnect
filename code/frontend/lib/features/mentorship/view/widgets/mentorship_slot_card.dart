import 'package:flutter/material.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enums.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_slot_summary.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentorship_status_badge.dart';

class MentorshipSlotCard extends StatelessWidget {
  const MentorshipSlotCard({
    required this.slot,
    required this.onTap,
    this.onJoin,
    this.isEnrolled = false,
    this.isHost = false,
    super.key,
  });

  final MentorshipSlotSummary slot;
  final VoidCallback onTap;
  final VoidCallback? onJoin;
  final bool isEnrolled;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final scheduleLabel =
        '${slot.scheduleType.label} • ${slot.startDate} at ${slot.startTime.length >= 5 ? slot.startTime.substring(0, 5) : slot.startTime}';
    final fillRatio = slot.capacity > 0
        ? (slot.currentMenteeCount / slot.capacity).clamp(0.0, 1.0)
        : 0.0;

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          'Hosted by ${slot.mentorName}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  MentorshipStatusBadge.slotStatus(slot.status, colors),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                slot.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      scheduleLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  MentorshipStatusBadge.mode(slot.mode, colors),
                ],
              ),
              const SizedBox(height: 12),
              // Capacity progress bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fillRatio,
                        minHeight: 6,
                        backgroundColor: colors.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          slot.isFull ? colors.secondary : colors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${slot.currentMenteeCount}/${slot.capacity} enrolled',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(onPressed: onTap, child: const Text('Details')),
                  if (onJoin != null &&
                      slot.isOpen &&
                      !isEnrolled &&
                      !isHost) ...[
                    FilledButton.icon(
                      onPressed: onJoin,
                      icon: const Icon(Icons.person_add_alt_1, size: 16),
                      label: const Text('Join Session'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
