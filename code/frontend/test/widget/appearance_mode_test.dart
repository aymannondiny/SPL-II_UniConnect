import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/app.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/core/theme/theme_preference.dart';
import 'package:uniconnect/features/home/model/workspace_access.dart';
import 'package:uniconnect/features/home/view/engineering_home_page.dart';

import '../../tool/support/fake_profile_repository.dart';

class _MemoryAppearanceStore implements AppearanceStore {
  String? stored;
  int writes = 0;

  @override
  Future<String?> read() async => stored;

  @override
  Future<void> write(String value) async {
    stored = value;
    writes++;
  }
}

void main() {
  testWidgets('switches among all three modes and restores the selection', (
    tester,
  ) async {
    final store = _MemoryAppearanceStore();
    await tester.pumpWidget(UniConnectApp(appearanceStore: store));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.text('Create your account'))).brightness,
      Brightness.dark,
    );
    expect(
      Theme.of(tester.element(find.text('Create your account')))
          .extension<EngineeringTheme>(),
      isNull,
    );

    await tester.tap(find.byKey(const Key('appearance-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light Mode'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Create your account'))).brightness,
      Brightness.light,
    );

    await tester.tap(find.byKey(const Key('appearance-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Engineering Mode'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Create your account')))
          .extension<EngineeringTheme>(),
      isNotNull,
    );
    expect(store.stored, 'engineering');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(UniConnectApp(appearanceStore: store));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Appearance: Engineering Mode'), findsOneWidget);
  });

  testWidgets('engineering dashboard uses real profile data and routes cards', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.engineering(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: SingleChildScrollView(
            child: EngineeringHomePage(
              name: 'Ayman Nondiny',
              profile: FakeProfileRepository.fixture(),
              access: const WorkspaceAccess(),
              onFeature: (value) => selected = value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('engineering-dashboard')), findsOneWidget);
    expect(find.textContaining('Ayman_'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Clubs'), findsOneWidget);
    expect(find.text('Career'), findsOneWidget);
    expect(
      find.textContaining('programme: "Software Engineering"'),
      findsOneWidget,
    );
    expect(find.textContaining('skills: 1'), findsOneWidget);

    await tester.tap(find.text('Projects'));
    expect(selected, 'Project finder');
    expect(tester.takeException(), isNull);
  });

  test('existing Light and Dark palettes remain distinct from Engineering', () {
    expect(AppTheme.light().brightness, Brightness.light);
    expect(AppTheme.dark().brightness, Brightness.dark);
    expect(AppTheme.light().extension<EngineeringTheme>(), isNull);
    expect(AppTheme.dark().extension<EngineeringTheme>(), isNull);
    expect(AppTheme.engineering().extension<EngineeringTheme>(), isNotNull);
    expect(
      AppTheme.dark().scaffoldBackgroundColor,
      isNot(AppTheme.engineering().scaffoldBackgroundColor),
    );
  });
}
