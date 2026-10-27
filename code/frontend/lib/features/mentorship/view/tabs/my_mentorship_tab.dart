import 'package:flutter/material.dart';
import 'package:uniconnect/features/mentorship/model/mentor_eligibility.dart';
import 'package:uniconnect/features/mentorship/view/widgets/participation_history.dart';
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
import 'package:uniconnect/features/mentorship/view/widgets/mentorship_section_header.dart';

class MyMentorshipTab extends StatefulWidget {
  const MyMentorshipTab({
    required this.controller,
    required this.repository,
    required this.userRole,
    this.yearOfStudy,
    super.key,
  });

  final MentorshipController controller;
  final MentorshipRepository repository;
  final String userRole;
  final int? yearOfStudy;

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

    final isEligibleMentor = MentorEligibility(
      role: widget.userRole,
      yearOfStudy: widget.yearOfStudy,
    ).canRegister;

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mentorInfo = Row(
                  children: [
                    Icon(
                      Icons.workspace_premium,
                      color: colors.primary,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
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
                  ],
                );
                final controls = Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Switch(
                      value:
                          controller.myProfile!.status ==
                          MentorStatus.available,
                      onChanged: controller.loading
                          ? null
                          : (val) {
                              controller.toggleMentorStatus(
                                val
                                    ? MentorStatus.available
                                    : MentorStatus.unavailable,
                              );
                            },
                    ),
                    FilledButton.icon(
                      onPressed: () => MentorshipSlotFormDialog.show(
                        context,
                        controller: controller,
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Host Session'),
                    ),
                  ],
                );

                if (constraints.maxWidth < 640) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      mentorInfo,
                      const SizedBox(height: 12),
                      controls,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: mentorInfo),
                    controls,
                  ],
                );
              },
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final registrationInfo = Row(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      color: colors.primary,
                      size: 28,
                    ),
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
                  ],
                );
                final registerButton = FilledButton(
                  onPressed: () => MentorRegistrationDialog.show(
                    context,
                    controller: controller,
                  ),
                  child: const Text('Register as Mentor'),
                );

                if (constraints.maxWidth < 640) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      registrationInfo,
                      const SizedBox(height: 12),
                      registerButton,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: registrationInfo),
                    const SizedBox(width: 12),
                    registerButton,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        ParticipationHistory(
          revision: controller.participationRevision,
          repository: widget.repository,
        ),
        const SizedBox(height: 24),
        // Enrolled Sessions Section
        MentorshipSectionHeader(
          title: 'Sessions You Joined',
          description:
              'Upcoming sessions where you reserved a spot as a mentee.',
          count: controller.myEnrolledSlots.length,
          countLabel: controller.myEnrolledSlots.length == 1
              ? 'session'
              : 'sessions',
        ),
        const SizedBox(height: 14),
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
          MentorshipSectionHeader(
            title: 'Sessions You Are Hosting',
            description: 'Manage enrollment, view mentee rosters, or update session details.',
            count: controller.myMentoringSlots.length,
            countLabel: controller.myMentoringSlots.length == 1
                ? 'session'
                : 'sessions',
          ),
          const SizedBox(height: 14),
          if (controller.myMentoringSlots.isEmpty)
            MentorshipEmptyState(
              icon: Icons.calendar_today_outlined,
              title: 'No Sessions Hosted Yet',
              description: 'You have not scheduled any mentorship sessions. Publish your first session to mentor peers!',
              actionIcon: Icons.add,
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
                  onReopen: () => controller.reopenSlot(slot.slotId),
                  busy: controller.loading,
                );
              },
            ),
        ],
      ],
    );
  }
}
