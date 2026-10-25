import 'package:uniconnect/features/authentication/model/auth_failure.dart';

/// Only an HTTP 404 from the own-profile endpoint means unregistered.
class MentorProfileMissing extends AuthFailure {
  const MentorProfileMissing()
    : super('You have not registered as a mentor yet.');
}
