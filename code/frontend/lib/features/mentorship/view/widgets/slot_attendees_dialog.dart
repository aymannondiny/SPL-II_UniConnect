import 'package:flutter/material.dart';
import 'package:uniconnect/features/mentorship/controller/mentorship_controller.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enrollment.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_slot_summary.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentorship_status_badge.dart';

class SlotAttendeesDialog extends StatefulWidget {
  const SlotAttendeesDialog({
    required this.slot,
    required this.controller,
    super.key,
  });

  final MentorshipSlotSummary slot;
  final MentorshipController controller;

  static Future<void> show(
    BuildContext context, {
    required MentorshipSlotSummary slot,
    required MentorshipController controller,
  }) {
    return showDialog(
      context: context,
      builder: (_) => SlotAttendeesDialog(slot: slot, controller: controller),
    );
  }

  @override
  State<SlotAttendeesDialog> createState() => _SlotAttendeesDialogState();
}

class _SlotAttendeesDialogState extends State<SlotAttendeesDialog> {
  List<MentorshipEnrollment>? _attendees;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await widget.controller.loadAttendees(widget.slot.slotId);
    if (mounted) {
      setState(() {
        _attendees = res;
        _loading = false;
      });
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.people_outline, color: colors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendee Roster',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.slot.topic,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
              Text(
                '${widget.slot.currentMenteeCount} of ${widget.slot.capacity} spots filled',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : (_attendees == null || _attendees!.isEmpty)
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.group_outlined, size: 48, color: colors.outline),
                                const SizedBox(height: 12),
                                Text(
                                  'No mentees have joined this session yet.',
                                  style: TextStyle(color: colors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _attendees!.length,
                            separatorBuilder: (_, __) => const Divider(height: 16),
                            itemBuilder: (context, index) {
                              final attendee = _attendees![index];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: colors.primaryContainer,
                                        child: Text(
                                          attendee.menteeName.isNotEmpty
                                              ? attendee.menteeName[0].toUpperCase()
                                              : 'M',
                                          style: TextStyle(
                                            color: colors.onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          attendee.menteeName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      MentorshipStatusBadge.enrollmentStatus(attendee.status, colors),
                                    ],
                                  ),
                                  if (attendee.learningGoal != null && attendee.learningGoal!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.lightbulb_outline, size: 16, color: colors.primary),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Goal: ${attendee.learningGoal!}',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (attendee.joinMessage != null && attendee.joinMessage!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Text(
                                        'Note: "${attendee.joinMessage!}"',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontStyle: FontStyle.italic,
                                          color: colors.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
              ),
              const Divider(),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
