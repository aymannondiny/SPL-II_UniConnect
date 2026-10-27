import '../support/dashboard_capture.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/career/view/career_board_page.dart';
import 'package:uniconnect/features/career/view/widgets/career_post_card.dart';

import '../../tool/support/fake_career_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDashboardFonts);
  for (final size in [
    const Size(1440, 900),
    const Size(390, 844),
    const Size(320, 640),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('alumni browse and own-post filter at $size dark=$dark', (
        tester,
      ) async {
        final captureKey = GlobalKey();
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            builder: (context, child) =>
                RepaintBoundary(key: captureKey, child: child!),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CareerBoardPage(
                    repository: FakeCareerRepository(),
                    role: 'ALUMNI',
                    currentUserId: 1,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await captureDashboard(
          tester,
          captureKey,
          'alumni-career-${size.width.toInt()}-${dark ? 'dark' : 'light'}',
        );
        expect(find.byType(CareerPostCard), findsNWidgets(4));
        for (final card in tester.widgetList<CareerPostCard>(
          find.byType(CareerPostCard),
        )) {
          expect(card.onToggleSave, isNull);
          expect(card.onApply, isNull);
          expect(card.onEdit, isNull);
          expect(card.onClose, isNull);
        }
        await tester.ensureVisible(find.text('My career posts'));
        await tester.tap(find.text('My career posts'));
        await tester.pumpAndSettle();
        expect(find.byType(CareerPostCard), findsOneWidget);
        final owned = tester.widget<CareerPostCard>(
          find.byType(CareerPostCard),
        );
        expect(owned.post.authorUserId, 1);
        expect(owned.onClose, isNotNull);
        expect(find.text('Backend engineer (Java)'), findsNothing);
        await tester.ensureVisible(find.text('Browse opportunities'));
        await tester.tap(find.text('Browse opportunities'));
        await tester.pumpAndSettle();
        expect(find.byType(CareerPostCard), findsNWidgets(4));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
