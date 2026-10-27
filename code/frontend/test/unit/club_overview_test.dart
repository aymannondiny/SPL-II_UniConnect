import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/features/club/model/club.dart';
import 'package:uniconnect/features/club/model/club_announcement.dart';
import 'package:uniconnect/features/club/model/club_event.dart';
import 'package:uniconnect/features/club/model/club_overview.dart';

void main() {
  final now = DateTime.utc(2026, 10, 27, 12);
  const club = Club(
    id: 1,
    name: 'Club',
    category: 'Technology',
    description: '',
    status: 'ACTIVE',
  );
  ClubAnnouncement announcement(String status, {DateTime? expires}) =>
      ClubAnnouncement(
        id: 1,
        clubName: 'Club',
        title: 'Announcement',
        content: '',
        priority: 'NORMAL',
        status: status,
        expiresAt: expires,
      );
  ClubEvent event(int id, int hours, {String status = 'PUBLISHED'}) =>
      ClubEvent(
        id: id,
        clubId: 1,
        clubName: 'Club',
        title: 'Event $id',
        description: '',
        startsAt: now.add(Duration(hours: hours)),
        endsAt: now.add(Duration(hours: hours + 2)),
        status: status,
      );

  test(
    'counts drafts separately and excludes expired or removed announcements',
    () {
      final overview = ClubOverview(club, [
        announcement('UNPUBLISHED'),
        announcement('REMOVED'),
        announcement('PUBLISHED', expires: now),
        announcement('PUBLISHED'),
      ], []);
      expect(overview.drafts, 1);
      expect(overview.publishedAt(now), 1);
    },
  );

  test(
    'upcoming list sorts live and future events and excludes past and removed',
    () {
      final overview = ClubOverview(club, [], [
        event(1, 8),
        event(2, -1),
        event(3, -5),
        event(4, 2, status: 'REMOVED'),
      ]);
      expect(overview.upcomingAt(now).map((item) => item.id), [2, 1]);
      expect(overview.events.length, 4);
    },
  );

  test('empty club has zero counts and no upcoming events', () {
    const overview = ClubOverview(club, [], []);
    expect(overview.drafts, 0);
    expect(overview.publishedAt(now), 0);
    expect(overview.upcomingAt(now), isEmpty);
  });
}
