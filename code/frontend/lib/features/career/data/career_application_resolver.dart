import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/career/data/career_repository.dart';
import 'package:uniconnect/features/career/model/career_models.dart';

/// Resolves a channel from current server data rather than a cached dialog.
class CareerApplicationResolver {
  const CareerApplicationResolver(this.repository);
  final CareerRepository repository;

  Future<Uri> resolve(int postId, CareerApplicationChannel channel) async {
    final post = await repository.detail(postId);
    if (!post.canApply || !post.applicationChannels.contains(channel)) {
      throw const AuthFailure(
        'This opportunity changed. Reopen its details to apply.',
      );
    }
    final uri = channel == CareerApplicationChannel.url
        ? Uri.tryParse(post.applicationUrl ?? '')
        : Uri(scheme: 'mailto', path: post.applicationEmail ?? '');
    final valid =
        uri != null &&
        switch (channel) {
          CareerApplicationChannel.url =>
            {'https', 'http'}.contains(uri.scheme) && uri.host.isNotEmpty,
          CareerApplicationChannel.email =>
            uri.scheme == 'mailto' && uri.path.contains('@'),
        };
    if (!valid) {
      throw const AuthFailure(
        'That application channel is no longer available.',
      );
    }
    return uri;
  }
}
