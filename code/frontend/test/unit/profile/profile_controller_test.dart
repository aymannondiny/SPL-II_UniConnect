import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/features/profile/controller/profile_controller.dart';

import '../../../tool/support/fake_profile_repository.dart';

void main() {
  test(
    'onboarding loads its catalog and returning profiles defer edit data',
    () async {
      final repository = FakeProfileRepository();
      final controller = ProfileController(repository);
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.loaded, isTrue);
      expect(controller.profile, isNull);
      expect(controller.visibility, 'CONNECTIONS_ONLY');
      repository.profile = FakeProfileRepository.fixture();
      repository.detailsVisibility = 'ALL_MEMBERS';
      await controller.load();
      expect(controller.profile!.name, 'Test Member');
      expect(controller.visibility, 'CONNECTIONS_ONLY');
      await controller.prepareEditing();
      expect(controller.visibility, 'ALL_MEMBERS');
    },
  );
  test(
    'load error does not masquerade as missing profile and retry recovers',
    () async {
      final repository = FakeProfileRepository()..failLoad = true;
      final controller = ProfileController(repository);
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.loaded, isFalse);
      expect(controller.error, isNotNull);
      repository.failLoad = false;
      await controller.load();
      expect(controller.loaded, isTrue);
      expect(controller.error, isNull);
    },
  );
  test(
    'partial privacy failure preserves saved profile and can be retried',
    () async {
      final repository = FakeProfileRepository()..failPrivacy = true;
      final controller = ProfileController(repository);
      addTearDown(controller.dispose);
      expect(
        await controller.save('STUDENT', {
          'fullName': 'Changed',
        }, 'ALL_MEMBERS'),
        isFalse,
      );
      expect(controller.profile!.name, 'Changed');
      expect(controller.error, contains('privacy'));
      repository.failPrivacy = false;
      expect(
        await controller.save('STUDENT', {
          'fullName': 'Changed',
        }, 'ALL_MEMBERS'),
        isTrue,
      );
      expect(controller.visibility, 'ALL_MEMBERS');
    },
  );
}
