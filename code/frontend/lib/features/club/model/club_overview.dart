import '../data/club_repository.dart';
import 'club.dart';
import 'club_announcement.dart';
import 'club_event.dart';

/// A read-only snapshot of publications visible to the current club operator.
class ClubOverview {
  const ClubOverview(this.club, this.announcements, this.events);

  final Club club;
  final List<ClubAnnouncement> announcements;
  final List<ClubEvent> events;

  static Future<ClubOverview> load(
    ClubRepository repository,
    int clubId,
  ) async {
    final club = repository.club(clubId);
    final announcements = repository.managedAnnouncements(clubId);
    final events = repository.managedEvents(clubId);
    // Wait for every request before exposing a consistent snapshot.
    final results = await Future.wait<Object>([club, announcements, events]);
    return ClubOverview(
      results[0] as Club,
      (await announcements).items,
      (await events).items,
    );
  }

  int get drafts =>
      announcements.where((item) => item.status == 'UNPUBLISHED').length;

  int publishedAt(DateTime now) => announcements
      .where(
        (item) =>
            item.status == 'PUBLISHED' &&
            (item.expiresAt == null || item.expiresAt!.isAfter(now)),
      )
      .length;

  List<ClubEvent> upcomingAt(DateTime now) =>
      events
          .where(
            (item) => item.status == 'PUBLISHED' && !item.endsAt.isBefore(now),
          )
          .toList()
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
}
