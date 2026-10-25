import 'package:uniconnect/core/widgets/meeting_link.dart';
import 'package:flutter/material.dart';
import 'package:uniconnect/features/mentorship/view/widgets/occurrence_schedule.dart';
import 'package:uniconnect/features/mentorship/data/mentorship_repository.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enums.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_slot.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentorship_status_badge.dart';

class MentorshipSlotDetailsDialog extends StatefulWidget {
  const MentorshipSlotDetailsDialog({
    required this.slotId,
    required this.repository,
    this.onJoin,
    this.isEnrolled = false,
    this.isHost = false,
    super.key,
  });

  final int slotId;
  final MentorshipRepository repository;
  final VoidCallback? onJoin;
  final bool isEnrolled;
  final bool isHost;

  static Future<void> show(
    BuildContext context, {
    required int slotId,
    required MentorshipRepository repository,
    VoidCallback? onJoin,
    bool isEnrolled = false,
    bool isHost = false,
  }) {
    return showDialog(
      context: context,
      builder: (_) => MentorshipSlotDetailsDialog(
        slotId: slotId,
        repository: repository,
        onJoin: onJoin,
        isEnrolled: isEnrolled,
        isHost: isHost,
      ),
    );
  }

  @override
  State<MentorshipSlotDetailsDialog> createState() =>
      _MentorshipSlotDetailsDialogState();
}

class _MentorshipSlotDetailsDialogState
    extends State<MentorshipSlotDetailsDialog> {
  MentorshipSlot? _slot;
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
      final data = await widget.repository.getSlotDetails(widget.slotId);
      if (mounted) {
        setState(() {
          _slot = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load mentorship session details.';
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
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 650),
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
    final slot = _slot!;
    final timeRange =
        '${slot.startTime.length >= 5 ? slot.startTime.substring(0, 5) : slot.startTime} - ${slot.endTime.length >= 5 ? slot.endTime.substring(0, 5) : slot.endTime}';

    return Column(
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
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mentor: ${slot.mentorName}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
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
        const SizedBox(height: 12),
        Row(
          children: [
            MentorshipStatusBadge.slotStatus(slot.status, colors),
            const SizedBox(width: 8),
            MentorshipStatusBadge.mode(slot.mode, colors),
          ],
        ),
        const SizedBox(height: 14),
        const Divider(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(slot.description, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 16),
                Text(
                  'Schedule & Time',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${slot.startDate} · $timeRange (${slot.scheduleType.label}) · Asia/Dhaka',
                      ),
                    ),
                  ],
                ),
                if (slot.mode == SlotMode.inPerson &&
                    slot.location != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 18,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Location: ${slot.location!}')),
                    ],
                  ),
                ],
                if (slot.mode == SlotMode.online &&
                    (slot.meetingLink != null ||
                        widget.isEnrolled ||
                        widget.isHost)) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.videocam, size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: slot.meetingLink == null
                            ? const Text(
                                'No meeting link is currently available',
                              )
                            : MeetingLink(url: slot.meetingLink!),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Capacity & Enrollment',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${slot.currentMenteeCount} / ${slot.capacity} spots filled (${slot.availableSeats} available)',
                ),
                if (slot.occurrenceDetails.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  OccurrenceSchedule(occurrences: slot.occurrenceDetails),
                ] else if (slot.occurrences.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Scheduled Dates · Asia/Dhaka',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: slot.occurrences.map((occ) {
                      return Chip(
                        label: Text(occ, style: const TextStyle(fontSize: 12)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (widget.onJoin != null &&
                slot.isOpen &&
                !widget.isEnrolled &&
                !widget.isHost) ...[
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onJoin!();
                },
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: const Text('Join Session'),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
