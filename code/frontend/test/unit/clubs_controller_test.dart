import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/club/controller/clubs_controller.dart';
import 'package:uniconnect/features/club/data/club_repository.dart';

import '../../tool/support/campus_fixture_api.dart';
import '../../tool/support/fake_session_repository.dart';

void main() {
  late SessionController session;
  late ClubsController controller;
  setUp(() async {
    session = SessionController(FakeSessionRepository());
    await session.login('member@example.org', 'test-password');
    controller = ClubsController(
      ClubRepository(ApiClient(client: CampusFixtureApi().client), session),
    );
  });
  tearDown(() {
    controller.dispose();
    session.dispose();
  });

  test(
    'initial campus load has independent directory and publication feeds',
    () async {
      await controller.load();
      expect(controller.clubs.items.length, 3);
      expect(controller.announcements.items.length, 2);
      expect(controller.events.items.length, 3);
      controller.searchClubs('Technology');
      await controller.clubs.load();
      expect(controller.clubs.items.single.id, 1);
      expect(controller.events.items.length, 3);
    },
  );

  test('club selection scopes both feeds and clearing history restores current events', () async {
    await controller.load();
    controller.select(controller.clubs.items.first);
    await Future.wait([
      controller.announcements.load(),
      controller.events.load(),
    ]);
    expect(controller.announcements.items.single.clubName, 'Programming Club');
    expect(controller.events.items.single.clubId, 1);
    controller.filterTiming('PAST');
    await controller.events.load();
    expect(controller.events.items.single.id, 24);
    controller.select(null);
    await controller.events.load();
    expect(controller.timing, 'ALL');
    expect(controller.events.items.length, 3);
  });

  test(
    'global history is unavailable and live timing has a real empty state',
    () async {
      controller.filterTiming('PAST');
      expect(controller.timing, 'ALL');
      controller.filterTiming('ACTIVE');
      await controller.events.load();
      expect(controller.events.items, isEmpty);
      expect(controller.events.error, isNull);
      controller.setActive(false);
      expect(controller.active, isFalse);
    },
  );
}
