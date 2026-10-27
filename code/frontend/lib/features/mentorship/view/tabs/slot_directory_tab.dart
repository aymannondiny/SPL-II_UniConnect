import 'package:flutter/material.dart';
import 'package:uniconnect/features/mentorship/controller/mentorship_controller.dart';
import 'package:uniconnect/features/mentorship/data/mentorship_repository.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enums.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_filter_params.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_slot_summary.dart';
import 'package:uniconnect/features/mentorship/view/widgets/join_slot_dialog.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentorship_empty_state.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentorship_slot_card.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentorship_slot_details_dialog.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentorship_filter_toolbar.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentorship_section_header.dart';

class SlotDirectoryTab extends StatefulWidget {
  const SlotDirectoryTab({
    required this.controller,
    required this.repository,
    super.key,
  });

  final MentorshipController controller;
  final MentorshipRepository repository;

  @override
  State<SlotDirectoryTab> createState() => _SlotDirectoryTabState();
}

class _SlotDirectoryTabState extends State<SlotDirectoryTab> {
  late final TextEditingController _searchController;

@override
void initState() {
  super.initState();

  _searchController = TextEditingController(
    text: widget.controller.slotFilters.topic ?? '',
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) widget.controller.ensureSlots();
  });
}

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    widget.controller.updateSlotFilters(
      widget.controller.slotFilters.copyWith(topic: value),
      debounce: true,
    );
  }

  void _onModeFilter(SlotMode? mode) {
    widget.controller.updateSlotFilters(
      widget.controller.slotFilters.copyWith(
        mode: mode,
        clearMode: mode == null,
      ),
    );
  }

  void _clearFilters() {
    _searchController.clear();
    widget.controller.updateSlotFilters(const SlotFilterParams());
  }

  bool _isHost(MentorshipSlotSummary slot) =>
      widget.controller.myProfile?.mentorProfileId == slot.mentorProfileId ||
      widget.controller.myMentoringSlots.any(
        (hosted) => hosted.slotId == slot.slotId,
      );

  bool _isEnrolled(MentorshipSlotSummary slot) => widget
      .controller
      .myEnrolledSlots
      .any((joined) => joined.slotId == slot.slotId);

  void _openDetails(MentorshipSlotSummary slot) {
    MentorshipSlotDetailsDialog.show(
      context,
      slotId: slot.slotId,
      repository: widget.repository,
      isHost: _isHost(slot),
      isEnrolled: _isEnrolled(slot),
      controller: widget.controller,
    );
  }

  void _joinSlot(MentorshipSlotSummary slot) {
    JoinSlotDialog.show(context, slot: slot, controller: widget.controller);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MentorshipSectionHeader(
          title: 'Explore Mentorship Sessions',
          description: 'Join interactive group and one-on-one sessions led by peer mentors.',
          count: controller.totalSlots,
          countLabel: controller.totalSlots == 1 ? 'session' : 'sessions',
        ),
        const SizedBox(height: 16),
        MentorshipFilterToolbar(
          searchController: _searchController,
          onSearchChanged: _onSearch,
          hintText: 'Search sessions by topic...',
          onClear: controller.slotFilters.hasFilters ? _clearFilters : null,
          trailingFilter: SegmentedButton<SlotMode?>(
            segments: const [
              ButtonSegment(value: null, label: Text('All')),
              ButtonSegment(value: SlotMode.online, label: Text('Online')),
              ButtonSegment(value: SlotMode.inPerson, label: Text('In-person')),
            ],
            selected: {controller.slotFilters.mode},
            onSelectionChanged: (selected) {
              _onModeFilter(selected.first);
            },
          ),
        ),
        const SizedBox(height: 16),
        if (controller.slotsLoading && controller.slots.isNotEmpty)
          const LinearProgressIndicator(),
        if (controller.slotsLoading && controller.slots.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (controller.slots.isEmpty)
          const MentorshipEmptyState(
            icon: Icons.event_busy_outlined,
            title: 'No Sessions Available',
            description: 'There are currently no sessions matching your criteria. Check back soon or request a topic from a mentor!',
          )
        else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.slots.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final slot = controller.slots[index];
              return MentorshipSlotCard(
                slot: slot,
                isHost: _isHost(slot),
                isEnrolled: _isEnrolled(slot),
                onTap: () => _openDetails(slot),
                onJoin: () => _joinSlot(slot),
              );
            },
          ),
          if (controller.slots.length < controller.totalSlots) ...[
            const SizedBox(height: 16),
            Center(
              child: controller.slotsLoadingMore
                  ? const CircularProgressIndicator()
                  : OutlinedButton(
                      onPressed: () => controller.loadSlots(more: true),
                      child: const Text('Load More Sessions'),
                    ),
            ),
          ],
        ],
      ],
    );
  }
}
