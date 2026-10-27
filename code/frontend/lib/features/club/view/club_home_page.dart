import 'package:flutter/material.dart';
import 'package:uniconnect/core/widgets/section_card.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';

import '../data/club_repository.dart';
import '../model/club_overview.dart';
import '../model/club_workspace_context.dart';
import 'widgets/club_overview_metrics.dart';

/// Club landing destination; publication editing belongs to Club workspace.
class ClubHomePage extends StatefulWidget {
  const ClubHomePage({
    required this.repository,
    required this.clubContext,
    required this.onManage,
    required this.active,
    super.key,
  });
  final ClubRepository repository;
  final ClubWorkspaceContext clubContext;
  final VoidCallback onManage;
  final bool active;

  @override
  State<ClubHomePage> createState() => _ClubHomePageState();
}

class _ClubHomePageState extends State<ClubHomePage> {
  late Future<ClubOverview> _overview;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant ClubHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((!oldWidget.active && widget.active) ||
        oldWidget.clubContext.key != widget.clubContext.key ||
        oldWidget.repository != widget.repository) {
      _reload();
    }
  }

  void _reload() {
    _overview = ClubOverview.load(
      widget.repository,
      widget.clubContext.clubId!,
    );
  }

  void _refresh() => setState(_reload);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SectionCard(
        title: 'Club overview',
        subtitle: widget.clubContext.label,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'See what is happening in your club, then head to your workspace to manage publications.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: widget.onManage,
                  icon: const Icon(Icons.groups_outlined),
                  label: const Text('Open club workspace'),
                ),
                OutlinedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh overview'),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      FutureBuilder<ClubOverview>(
        future: _overview,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return SectionCard(
              title: 'Overview unavailable',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    snapshot.error is AuthFailure
                        ? (snapshot.error! as AuthFailure).message
                        : 'Unable to load your club overview. Please retry.',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return _content(snapshot.data!);
        },
      ),
    ],
  );

  Widget _content(ClubOverview overview) {
    final now = DateTime.now();
    final upcoming = overview.upcomingAt(now);
    final active = overview.club.status == 'ACTIVE';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: active ? 'Publishing is active' : 'Publishing is paused',
          subtitle: overview.club.category,
          child: Text(
            active
                ? 'Your club can share announcements and create events from Club workspace.'
                : 'New events and announcement publishing are unavailable. Open Club workspace to review existing content and announcement drafts.',
          ),
        ),
        const SizedBox(height: 24),
        ClubOverviewMetrics(overview: overview, now: now),
        const SizedBox(height: 24),
        SectionCard(
          title: 'Coming up next',
          subtitle: 'Upcoming and live events visible to your assignment · local time',
          child: upcoming.isEmpty
              ? const Text(
                  'No upcoming events yet. Plan your next event in Club workspace.',
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final event in upcoming.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${event.timingAt(now)} · ${event.startsAt.toLocal().toString().substring(0, 16)}',
                            ),
                            Text(event.location ?? 'Location to be announced'),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
