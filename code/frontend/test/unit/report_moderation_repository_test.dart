import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/network/authenticated_json_client.dart';
import 'package:uniconnect/features/administration/data/account_moderation_repository.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/reporting/data/report_repository.dart';

import '../../tool/support/fake_session_repository.dart';
import '../../tool/support/workflow_fixture_api.dart';

void main() {
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

  test(
    'report submission and owner reads do not select administration context',
    () async {
      final reports = ReportRepository(api);
      await reports.submit('PROJECT', 1, ' Concern ');
      expect((await reports.list()).items.single.id, 12);
      expect((await reports.detail(12)).snapshot, isNull);
      expect(
        fixture.requests.any(
          (request) => request.url.path.contains('contexts'),
        ),
        isFalse,
      );
      expect(jsonDecode(fixture.requests.first.body), {
        'targetType': 'PROJECT',
        'targetId': 1,
        'reason': 'Concern',
      });
    },
  );

  test('review preserves the selected context and sends a reporter-safe resolution', () async {
    final reports = ReportRepository(api);
    await reports.review(12);
    expect(
      (await reports.detail(12, administration: true)).status,
      'UNDER_REVIEW',
    );
    await reports.resolve(12, {
      'outcome': 'NO_ACTION',
      'resolutionSummary': 'Reviewed.',
      'internalNotes': null,
      'actionEvidence': null,
    });
    expect(fixture.reportStatus, 'NO_ACTION');
    expect(
      fixture.requests.any((request) => request.url.path.contains('contexts')),
      isFalse,
    );
    expect(
      fixture.requests.every(
        (request) => request.headers['authorization'] == 'Bearer access-login',
      ),
      isTrue,
    );
  });

  test(
    'account transitions send explicit confirmation and retain action IDs',
    () async {
      final accounts = AccountModerationRepository(api);
      expect((await accounts.search()).items.single.canSuspend, isTrue);
      await accounts.transition(2, suspend: true, reason: ' Reviewed policy ');
      expect((await accounts.detail(2)).canRestore, isTrue);
      final transition = fixture.requests.firstWhere(
        (request) => request.url.path.endsWith('/suspend'),
      );
      expect(jsonDecode(transition.body), {
        'reason': 'Reviewed policy',
        'confirm': true,
      });
      expect((await accounts.audit(2)).single['actionId'], 17);
      await accounts.transition(2, suspend: false, reason: 'Restored');
      expect(fixture.accountStatus, 'ACTIVE');
    },
  );

  for (final status in [401, 403, 404, 409]) {
    test('HTTP $status is an actionable failure', () async {
      final badClient = ApiClient(
        client: MockClient((_) async => http.Response('{}', status)),
      );
      addTearDown(badClient.close);
      await expectLater(
        ReportRepository(AuthenticatedJsonClient(badClient, session))
            .detail(12),
        throwsA(isA<AuthFailure>()),
      );
      if (status == 401) expect(session.account, isNull);
    });
  }

  test('valid JSON with a broken report contract is rejected', () async {
    final badClient = ApiClient(
      client: MockClient(
        (_) async => http.Response('{"items":[{}],"totalElements":1}', 200),
      ),
    );
    addTearDown(badClient.close);
    await expectLater(
      ReportRepository(AuthenticatedJsonClient(badClient, session)).list(),
      throwsA(isA<AuthFailure>()),
    );
  });
}
