import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/club/data/club_repository.dart';
import 'package:uniconnect/features/club/model/club_workspace_context.dart';
import 'package:uniconnect/features/home/controller/workspace_context_controller.dart';

import '../../tool/support/fake_session_repository.dart';

const personal = ClubWorkspaceContext(contextType: 'PERSONAL');
const club = ClubWorkspaceContext(
  contextType: 'CLUB',
  assignmentId: 10,
  clubId: 1,
  clubName: 'Programming Club',
  clubRole: 'REPRESENTATIVE',
);
const administration = ClubWorkspaceContext(
  contextType: 'SYSTEM_ADMINISTRATION',
);

class ContextRepository extends ClubRepository {
  ContextRepository(super.client, super.session);
  List<ClubWorkspaceContext> options = [personal, club];
  ClubWorkspaceContext active = personal;
  Completer<void>? pending;
  bool fail = false;
  int writes = 0;

  @override
  Future<({ClubWorkspaceContext active, List<ClubWorkspaceContext> available})>
  workspaceContexts() async => (active: active, available: options);

  @override
  Future<void> selectContext(String type, {int? assignmentId}) async {
    writes++;
    if (pending != null) await pending!.future;
    if (fail) {
      throw const AuthFailure('Assignment revoked. Refresh workspaces.');
    }
    active = options.firstWhere(
      (item) => item.contextType == type && item.assignmentId == assignmentId,
    );
  }
}

void main() {
  late ContextRepository repository;
  setUp(() {
    final client = ApiClient();
    final session = SessionController(FakeSessionRepository());
    repository = ContextRepository(client, session);
    addTearDown(client.close);
    addTearDown(session.dispose);
  });

  test(
    'switch waits for server acceptance and deduplicates concurrent selection',
    () async {
      final controller = WorkspaceContextController(repository, 'STUDENT');
      addTearDown(controller.dispose);
      await controller.load();
      repository.pending = Completer<void>();
      final selecting = controller.select(club.key);
      expect(controller.busy, isTrue);
      expect(controller.selected.key, personal.key);
      expect(await controller.select(club.key), isFalse);
      expect(repository.writes, 1);
      repository.pending!.complete();
      expect(await selecting, isTrue);
      expect(controller.access.club, isTrue);
    },
  );

  test('failed selection preserves personal access and refresh removes revoked assignment', () async {
    final controller = WorkspaceContextController(repository, 'STUDENT');
    addTearDown(controller.dispose);
    await controller.load();
    repository.fail = true;
    expect(await controller.select(club.key), isFalse);
    expect(controller.selected.key, personal.key);
    expect(controller.error, contains('revoked'));
    repository.options = [personal];
    await controller.load();
    expect(controller.available, [personal]);
    expect(await controller.select(club.key), isFalse);
  });

  test(
    'admin lands in administration and can explicitly return to personal',
    () async {
      repository.options = [personal, administration, club];
      final controller = WorkspaceContextController(repository, 'SYSTEM_ADMIN');
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.access.administration, isTrue);
      expect(controller.available, isNot(contains(club)));
      expect(await controller.select(personal.key), isTrue);
      await controller.load();
      expect(controller.access.personal, isTrue);
    },
  );

  test(
    'late server response after disposal does not notify disposed listeners',
    () async {
      final controller = WorkspaceContextController(repository, 'STUDENT');
      await controller.load();
      repository.pending = Completer<void>();
      final selecting = controller.select(club.key);
      controller.dispose();
      repository.pending!.complete();
      expect(await selecting, isFalse);
    },
  );
}
