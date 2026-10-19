import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/connection/controller/connection_controller.dart';
import 'package:uniconnect/features/connection/data/connection_repository.dart';
import 'package:uniconnect/features/connection/model/connection_models.dart';
import 'package:uniconnect/features/connection/model/member_filters.dart';

import '../../tool/support/fake_session_repository.dart';

void main() {
  late ApiClient client;
  late SessionController session;
  late _DeferredRepository repository;
  late ConnectionController controller;
  setUp(() {
    client = ApiClient();
    session = SessionController(FakeSessionRepository());
    repository = _DeferredRepository(client, session);
    controller = ConnectionController(repository);
  });
  tearDown(() {
    controller.dispose();
    session.dispose();
    client.close();
  });

  test('late search responses cannot overwrite newer results', () async {
    final first = controller.search('old');
    final second = controller.search('new');
    repository.pending[1].complete(_page(3));
    await second;
    repository.pending[0].complete(_page(2));
    await first;
    expect(controller.members.single.id, 3);
    expect(controller.loading, isFalse);
  });

  test('load more keeps submitted filters and deduplicates results', () async {
    final first = controller.search('submitted');
    repository.pending[0].complete(_page(2, total: 3));
    await first;
    final more = controller.search('unsubmitted edit', more: true);
    expect(repository.names, ['submitted', 'submitted']);
    expect(repository.pages, [0, 1]);
    repository.pending[1].complete(
      MemberSearchPage(items: [_member(2), _member(3)], total: 3),
    );
    await more;
    expect(controller.members.map((m) => m.id), [2, 3]);
  });

  test('failed load more retains results and retries the same page', () async {
    final first = controller.search('');
    repository.pending[0].complete(_page(2, total: 3));
    await first;
    final more = controller.search('', more: true);
    repository.pending[1].completeError(const AuthFailure('Try again'));
    await more;
    expect(controller.members.single.id, 2);
    expect(controller.error, 'Try again');
    final retry = controller.search('', more: true);
    expect(repository.pages, [0, 1, 1]);
    repository.pending[2].complete(_page(3, total: 3));
    await retry;
    expect(controller.error, isNull);
  });

  test('navigation invalidates in-flight discovery', () async {
    final first = controller.search('old');
    controller.invalidate();
    repository.pending[0].complete(_page(2));
    await first;
    expect(controller.members, isEmpty);
  });

  test('privacy flag prevents details leaking into the headline', () {
    final member = MemberProfile.fromJson({
      'userId': 2,
      'fullName': 'Private Member',
      'platformRole': 'ALUMNI',
      'detailsVisible': false,
      'details': {
        'bio': 'Hidden',
        'alumni': {'currentPosition': 'Hidden position'},
      },
    });
    expect(member.details, isNull);
    expect(member.headline, 'Alumni');
  });
}

MemberProfile _member(int id) =>
    MemberProfile(id, 'Member $id', 'Student', null, false, null);
MemberSearchPage _page(int id, {int total = 1}) =>
    MemberSearchPage(items: [_member(id)], total: total);

class _DeferredRepository extends ConnectionRepository {
  _DeferredRepository(super.client, super.session);
  final pending = <Completer<MemberSearchPage>>[];
  final names = <String>[];
  final pages = <int>[];
  @override
  Future<MemberSearchPage> members(MemberFilters filters, int page) {
    names.add(filters.name);
    pages.add(page);
    final response = Completer<MemberSearchPage>();
    pending.add(response);
    return response.future;
  }
}
