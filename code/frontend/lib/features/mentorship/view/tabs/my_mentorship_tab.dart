import 'package:flutter/material.dart';
import 'package:uniconnect/features/mentorship/controller/mentorship_controller.dart';
import 'package:uniconnect/features/mentorship/data/mentorship_repository.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enums.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_slot_summary.dart';
import 'package:uniconnect/features/mentorship/view/widgets/enrolled_session_card.dart';
import 'package:uniconnect/features/mentorship/view/widgets/host_slot_card.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentor_registration_dialog.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentorship_empty_state.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentorship_slot_details_dialog.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentorship_slot_form_dialog.dart';
import 'package:uniconnect/features/mentorship/view/widgets/slot_attendees_dialog.dart';

class MyMentorshipTab extends StatefulWidget {
  const MyMentorshipTab({
    required this.controller,
    required this.repository,
    required this.userRole,
    super.key,
  });

  final MentorshipController controller;
  final MentorshipRepository repository;
  final String userRole;

  @override
  State<MyMentorshipTab> createState() => _MyMentorshipTabState();
}

class _MyMentorshipTabState extends State<MyMentorshipTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.controller.loadMySessions();
        widget.controller.loadMyProfile();
      }
    });
  }

  void _openDetails(MentorshipSlotSummary slot, {bool isHost = false}) {
    MentorshipSlotDetailsDialog.show(
      context,
      slotId: slot.slotId,
      repository: widget.repository,
      isEnrolled: !isHost,
      isHost: isHost,
    );
  }

  void _openAttendees(MentorshipSlotSummary slot) {
    SlotAttendeesDialog.show(
      context,
      slot: slot,
      controller: widget.controller,
    );
  }

  void _editSlot(MentorshipSlotSummary slot) {
    MentorshipSlotFormDialog.show(
      context,
      controller: widget.controller,
      existingSlot: slot,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final controller = widget.controller;

    final isEligibleMentor =
        widget.userRole == 'STUDENT' || widget.userRole == 'ALUMNI';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mentor profile banner
        if (controller.isRegisteredMentor && controller.myProfile != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.workspace_premium, color: colors.primary, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You are a Peer Mentor',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Status: ${controller.myProfile!.status.label}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: controller.myProfile!.status == MentorStatus.available,
                  onChanged: (val) {
                    controller.toggleMentorStatus(
                      val ? MentorStatus.available : MentorStatus.unavailable,
                    );
                  },
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => MentorshipSlotFormDialog.show(
                    context,
                    controller: controller,
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Host Session'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ] else if (isEligibleMentor) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.school_outlined, color: colors.primary, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offer Your Guidance to Peers',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Senior students and alumni can register as peer mentors and host study slots.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => MentorRegistrationDialog.show(
                    context,
                    controller: controller,
                  ),
                  child: const Text('Register as Mentor'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Enrolled Sessions Section
        Text(
          'Sessions You Joined',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Upcoming sessions where you reserved a spot as a mentee.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (controller.sessionsLoading && controller.myEnrolledSlots.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (controller.myEnrolledSlots.isEmpty)
          MentorshipEmptyState(
            icon: Icons.event_available_outlined,
            title: 'No Enrolled Sessions',
            description: 'You have not joined any upcoming mentorship sessions yet. Explore available slots in the Discover Sessions tab!',
            actionLabel: 'Discover Sessions',
            onAction: () => controller.selectTab(MentorshipTab.slots),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.myEnrolledSlots.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final slot = controller.myEnrolledSlots[index];
              return EnrolledSessionCard(
                slot: slot,
                onTap: () => _openDetails(slot, isHost: false),
                onLeave: () => controller.leaveSlot(slot.slotId),
              );
            },
          ),

        if (controller.isRegisteredMentor) ...[
          const SizedBox(height: 32),
          Text(
            'Sessions You Are Hosting',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage enrollment, view mentee rosters, or update session details.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (controller.myMentoringSlots.isEmpty)
            MentorshipEmptyState(
              icon: Icons.calendar_today_outlined,
              title: 'No Sessions Hosted Yet',
              description: 'You have not scheduled any mentorship sessions. Publish your first session to mentor peers!',
              actionLabel: 'Host New Session',
              onAction: () => MentorshipSlotFormDialog.show(
                context,
                controller: controller,
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.myMentoringSlots.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final slot = controller.myMentoringSlots[index];
                return HostSlotCard(
                  slot: slot,
                  onTap: () => _openDetails(slot, isHost: true),
                  onViewAttendees: () => _openAttendees(slot),
                  onEdit: () => _editSlot(slot),
                  onClose: () => controller.closeSlot(slot.slotId),
                  onCancel: () => controller.cancelSlot(slot.slotId),
                );
              },
            ),
        ],
      ],
    );
  }
}
