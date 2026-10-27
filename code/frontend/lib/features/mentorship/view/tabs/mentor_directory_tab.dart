import 'package:flutter/material.dart';
import 'package:uniconnect/features/mentorship/controller/mentorship_controller.dart';
import 'package:uniconnect/features/mentorship/data/mentorship_repository.dart';
import 'package:uniconnect/features/mentorship/model/mentor_summary.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_filter_params.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentor_card.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentor_profile_dialog.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentorship_empty_state.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentorship_filter_toolbar.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentorship_section_header.dart';

class MentorDirectoryTab extends StatefulWidget {
  const MentorDirectoryTab({
    required this.controller,
    required this.repository,
    super.key,
  });

  final MentorshipController controller;
  final MentorshipRepository repository;

  @override
  State<MentorDirectoryTab> createState() => _MentorDirectoryTabState();
}

class _MentorDirectoryTabState extends State<MentorDirectoryTab> {
  late final TextEditingController _searchController;

@override
void initState() {
  super.initState();

  _searchController = TextEditingController(
    text: widget.controller.mentorFilters.topic ?? '',
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) widget.controller.ensureMentors();
  });
}

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    widget.controller.updateMentorFilters(
      widget.controller.mentorFilters.copyWith(topic: value),
      debounce: true,
    );
  }

  void _onYearChanged(int? year) {
    widget.controller.updateMentorFilters(
      widget.controller.mentorFilters.copyWith(
        yearOfStudy: year == 0 ? null : year,
        clearYear: year == null || year == 0,
        role: year == 0 ? 'ALUMNI' : null,
        clearRole: year != 0,
      ),
    );
  }

  void _onClearFilters() {
    _searchController.clear();
    widget.controller.updateMentorFilters(const MentorFilterParams());
  }

  void _openMentorProfile(MentorSummary mentor) {
    MentorProfileDialog.show(
      context,
      mentorProfileId: mentor.mentorProfileId,
      repository: widget.repository,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MentorshipSectionHeader(
          title: 'Browse Peer Mentors',
          description: 'Connect with experienced students and alumni across departments.',
          count: controller.totalMentors,
          countLabel: controller.totalMentors == 1 ? 'mentor' : 'mentors',
        ),
        const SizedBox(height: 16),
        MentorshipFilterToolbar(
          searchController: _searchController,
          onSearchChanged: _onSearch,
          selectedYear: controller.mentorFilters.role == 'ALUMNI'
              ? 0
              : controller.mentorFilters.yearOfStudy,
          onYearChanged: _onYearChanged,
          onClear: controller.mentorFilters.hasFilters ? _onClearFilters : null,
          hintText: 'Search by topic or expertise...',
        ),
        const SizedBox(height: 16),
        if (controller.mentorsLoading && controller.mentors.isNotEmpty)
          const LinearProgressIndicator(),
        if (controller.mentorsLoading && controller.mentors.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (controller.mentors.isEmpty)
          MentorshipEmptyState(
            icon: Icons.person_search_outlined,
            title: 'No Mentors Found',
            description: controller.mentorFilters.hasFilters
                ? 'No peer mentors match the current search filters. Try clearing your filters.'
                : 'No peer mentors are registered or available at the moment.',
            actionLabel: controller.mentorFilters.hasFilters
                ? 'Reset Filters'
                : null,
            actionIcon: Icons.refresh,
            onAction: controller.mentorFilters.hasFilters
                ? _onClearFilters
                : null,
          )
        else ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900
                  ? 3
                  : constraints.maxWidth > 600
                  ? 2
                  : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 210,
                ),
                itemCount: controller.mentors.length,
                itemBuilder: (context, index) {
                  final mentor = controller.mentors[index];
                  return MentorCard(
                    mentor: mentor,
                    onTap: () => _openMentorProfile(mentor),
                  );
                },
              );
            },
          ),
          if (controller.mentors.length < controller.totalMentors) ...[
            const SizedBox(height: 16),
            Center(
              child: controller.mentorsLoadingMore
                  ? const CircularProgressIndicator()
                  : OutlinedButton(
                      onPressed: () => controller.loadMentors(more: true),
                      child: const Text('Load More Mentors'),
                    ),
            ),
          ],
        ],
      ],
    );
  }
}
