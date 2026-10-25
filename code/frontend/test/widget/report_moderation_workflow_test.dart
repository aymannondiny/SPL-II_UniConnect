import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/network/authenticated_json_client.dart';
import 'package:uniconnect/core/session/session_scope.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/administration/data/account_moderation_repository.dart';
import 'package:uniconnect/features/administration/view/account_moderation_page.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/reporting/data/report_repository.dart';
import 'package:uniconnect/features/reporting/view/reports_page.dart';

import '../../tool/support/fake_session_repository.dart';
import '../../tool/support/workflow_fixture_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_QA')) return;
    final font = File('C:/Windows/Fonts/segoeui.ttf');
    if (await font.exists()) {
      await (FontLoader(
        'Roboto',
      )..addFont(font.readAsBytes().then(ByteData.sublistView))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  late SessionController session;
  late WorkflowFixtureApi fixture;
  late ApiClient client;
  late AuthenticatedJsonClient api;
  setUp(() async {
    session = SessionController(FakeSessionRepository());
    await session.login('member@example.org', 'test-password');
    fixture = WorkflowFixtureApi();
    client = ApiClient(client: fixture.client);
    api = AuthenticatedJsonClient(client, session);
  });
  tearDown(() {
    client.close();
    session.dispose();
  });

  Future<void> show(
    WidgetTester tester,
    Widget child,
    double width,
    bool dark,
  ) async {
    tester.view.physicalSize = Size(width, width < 600 ? 844 : 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      SessionScope(
        controller: session,
        child: MaterialApp(
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(padding: const EdgeInsets.all(16), child: child),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> screenshot(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('CAPTURE_QA')) return;
    final boundary = tester.firstRenderObject<RenderRepaintBoundary>(
      find.byType(RepaintBoundary).first,
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('build/workflow-qa');
      await directory.create(recursive: true);
      await File('${directory.path}/$name.png')
          .writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  }

  for (final width in [1440.0, 390.0, 320.0]) {
    for (final dark in [false, true]) {
      testWidgets('report submit and review at $width dark=$dark', (
        tester,
      ) async {
        final reports = ReportRepository(api);
        await show(tester, ReportsPage(repository: reports), width, dark);
        await screenshot(tester, 'reports-${width.toInt()}-$dark');
        await tester.tap(find.text('Report content'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Content ID'),
          '1',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Reason'),
          'Please review the content.',
        );
        await tester.tap(find.text('Submit report'));
        await tester.pumpAndSettle();
        expect(
          fixture.requests.any(
            (request) =>
                request.method == 'POST' &&
                request.url.path == '/api/v1/reports',
          ),
          isTrue,
        );
        expect(tester.takeException(), isNull);

        await show(
          tester,
          ReportsPage(
            key: const ValueKey('admin-reports'),
            repository: reports,
            administration: true,
            currentUserId: 1,
          ),
          width,
          dark,
        );
        await tester.tap(find.text('Campus collaboration project 1'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Claim review'));
        await tester.pumpAndSettle();
        expect(fixture.reportStatus, 'UNDER_REVIEW');
        await tester.tap(find.text('Resolve'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Summary visible to reporter'),
          'Reviewed; no action required.',
        );
        await tester.tap(find.text('Resolve report').last);
        await tester.pumpAndSettle();
        expect(fixture.reportStatus, 'NO_ACTION');
        expect(find.text('Reviewed; no action required.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        'account confirmation, suspension and restoration at $width dark=$dark',
        (tester) async {
          await show(
            tester,
            AccountModerationPage(repository: AccountModerationRepository(api)),
            width,
            dark,
          );
          await screenshot(tester, 'accounts-${width.toInt()}-$dark');
          await tester.tap(find.text('Nadia Rahman'));
          await tester.pumpAndSettle();
          expect(find.textContaining('Action #17'), findsOneWidget);
          await tester.tap(find.text('Suspend'));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<FilledButton>(
                  find.widgetWithText(FilledButton, 'Suspend account'),
                )
                .onPressed,
            isNull,
          );
          await tester.enterText(
            find.byType(TextFormField),
            'Reviewed under policy.',
          );
          await tester.tap(find.byType(CheckboxListTile));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Suspend account'));
          await tester.pumpAndSettle();
          expect(fixture.accountStatus, 'SUSPENDED');
          await tester.tap(find.text('Restore'));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byType(TextFormField),
            'Access restored after review.',
          );
          await tester.tap(find.byType(CheckboxListTile));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Restore account'));
          await tester.pumpAndSettle();
          expect(fixture.accountStatus, 'ACTIVE');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
