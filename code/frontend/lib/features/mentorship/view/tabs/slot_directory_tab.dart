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
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.controller.slots.isEmpty && !widget.controller.slotsLoading) {
      widget.controller.loadSlots();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    widget.controller.updateSlotFilters(
      widget.controller.slotFilters.copyWith(topic: value),
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

  void _openDetails(MentorshipSlotSummary slot) {
    MentorshipSlotDetailsDialog.show(
      context,
      slotId: slot.slotId,
      repository: widget.repository,
      onJoin: () => _joinSlot(slot),
    );
  }

  void _joinSlot(MentorshipSlotSummary slot) {
    JoinSlotDialog.show(
      context,
      slot: slot,
      controller: widget.controller,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final controller = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explore Mentorship Sessions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Join interactive group and one-on-one sessions led by peer mentors.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (controller.totalSlots > 0)
              Text(
                '${controller.totalSlots} sessions found',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: 'Search sessions by topic...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              SegmentedButton<SlotMode?>(
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
            ],
          ),
        ),
        const SizedBox(height: 16),
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
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final slot = controller.slots[index];
              return MentorshipSlotCard(
                slot: slot,
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
