import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/connection/data/connection_repository.dart';
import 'package:uniconnect/features/connection/view/connection_page.dart';
import 'package:uniconnect/features/connection/view/member_profile_page.dart';
import 'package:uniconnect/features/chat/model/chat_models.dart';

import '../../tool/support/fake_session_repository.dart';
import '../../tool/support/member_fixture_api.dart';

void main() {
  late SessionController session;
  late MemberFixtureApi api;
  late ApiClient client;
  late ConnectionRepository repository;
  setUp(() async {
    session = SessionController(FakeSessionRepository());
    await session.login('member@iut-dhaka.edu', 'password');
    api = MemberFixtureApi();
    client = ApiClient(client: api.client);
    repository = ConnectionRepository(client, session);
  });
  tearDown(() {
    session.dispose();
    client.close();
  });

  for (final size in [
    const Size(1440, 900),
    const Size(1024, 768),
    const Size(390, 844),
    const Size(320, 640),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('populated connections and requests at $size dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        ChatConnection? recipient;
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ConnectionPage(
                    session: session,
                    repository: repository,
                    onOpenMessages: (value) => recipient = value,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Nafisa Rahman'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Message'));
        await tester.tap(find.text('Message'));
        await tester.pump();
        expect(recipient?.userId, 2);
        expect(recipient?.fullName, 'Nafisa Rahman');
        await tester.ensureVisible(find.textContaining('Received').first);
        await tester.tap(find.textContaining('Received').first);
        await tester.pumpAndSettle();
        expect(find.text('Arif Hasan'), findsOneWidget);
        await tester.ensureVisible(find.text('Accept'));
        await tester.tap(find.text('Accept'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.textContaining('Connected').first);
        await tester.tap(find.textContaining('Connected').first);
        await tester.pumpAndSettle();
        expect(find.text('Arif Hasan'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets(
        'populated discovery and public profile at $size dark=$dark',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark() : AppTheme.light(),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ConnectionPage(
                      session: session,
                      repository: repository,
                      initialDiscovery: true,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('25 people'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.text('View profile').first);
          await tester.tap(find.text('View profile').first);
          await tester.pumpAndSettle();
          expect(find.byType(MemberProfilePage), findsOneWidget);
          expect(find.text('Nafisa Rahman'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pageBack();
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Load more people'));
          await tester.tap(find.text('Load more people'));
          await tester.pumpAndSettle();
          expect(find.text('Community Member 26'), findsOneWidget);
          expect(find.text('Load more people'), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }

  testWidgets('private profile does not render hidden details', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MemberProfilePage(
          repository: repository,
          memberId: 3,
          onConnect: (_) async {},
          onMessage: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Private profile details'), findsOneWidget);
    expect(find.text('Skills & interests'), findsNothing);
    expect(find.text('Campus Labs'), findsNothing);
  });

  testWidgets(
    'filter validation prevents invalid year and sends valid filters',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              key: const PageStorageKey<String>('workspace-Discover'),
              child: ConnectionPage(
                session: session,
                repository: repository,
                initialDiscovery: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Filter people'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final year = find.widgetWithText(TextFormField, 'Graduation year');
      await tester.ensureVisible(year);
      await tester.enterText(year, '1800');
      await tester.ensureVisible(find.text('Apply filters'));
      await tester.tap(find.text('Apply filters'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a year from 1900 to 2200.'), findsOneWidget);
      await tester.enterText(year, '2024');
      await tester.tap(find.text('Apply filters'));
      await tester.pumpAndSettle();
      expect(
        api.requests
            .lastWhere((r) => r.url.path == '/api/v1/members')
            .url
            .queryParameters['graduationYear'],
        '2024',
      );
      await tester.ensureVisible(find.text('Clear filters'));
      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(find.text('25 people'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
