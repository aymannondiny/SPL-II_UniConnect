import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/career/data/career_application_resolver.dart';
import 'package:uniconnect/features/career/model/career_models.dart';

import '../../tool/support/fake_career_repository.dart';

class CurrentCareerRepository extends FakeCareerRepository {
  Map<String, dynamic> current = {
    'id': 101,
    'canApply': true,
    'status': 'PUBLISHED',
    'applicationChannels': ['URL', 'EMAIL'],
    'applicationUrl': 'https://example.org/current',
    'applicationEmail': 'careers@example.org',
  };
  int reads = 0;

  @override
  Future<CareerPost> detail(int postId) async {
    reads++;
    return CareerPost.fromJson(current);
  }
}

void main() {
  test('uses the current address every time the channel is selected', () async {
    final repository = CurrentCareerRepository();
    final resolver = CareerApplicationResolver(repository);
    expect(
      (await resolver.resolve(101, CareerApplicationChannel.url)).path,
      '/current',
    );
    repository.current['applicationUrl'] = 'https://example.org/updated';
    expect(
      (await resolver.resolve(101, CareerApplicationChannel.url)).path,
      '/updated',
    );
    expect(repository.reads, 2);
    expect(
      (await resolver.resolve(101, CareerApplicationChannel.email)).toString(),
      'mailto:careers@example.org',
    );
  });

  test('closed or removed channels cannot use cached details', () async {
    final repository = CurrentCareerRepository();
    final resolver = CareerApplicationResolver(repository);
    repository.current['canApply'] = false;
    await expectLater(
      resolver.resolve(101, CareerApplicationChannel.url),
      throwsA(isA<AuthFailure>()),
    );
    repository.current['canApply'] = true;
    repository.current['applicationChannels'] = ['EMAIL'];
    await expectLater(
      resolver.resolve(101, CareerApplicationChannel.url),
      throwsA(isA<AuthFailure>()),
    );
  });

  for (final address in ['javascript:alert(1)', 'https:', '/relative', '']) {
    test('rejects unsafe or incomplete application URL: $address', () async {
      final repository = CurrentCareerRepository();
      repository.current['applicationUrl'] = address;
      await expectLater(
        CareerApplicationResolver(repository)
            .resolve(101, CareerApplicationChannel.url),
        throwsA(isA<AuthFailure>()),
      );
    });
  }
}
