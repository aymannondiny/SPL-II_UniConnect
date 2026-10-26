import 'package:uniconnect/features/authentication/model/auth_failure.dart';

/// Converts contract mismatches into a recoverable error at the API boundary.
T parseResponse<T>(T Function() parse, {String resource = 'server'}) {
  try {
    return parse();
  } on AuthFailure {
    rethrow;
  } on Object {
    throw AuthFailure(
      'The $resource response has an unexpected format. Retry, and contact support if this continues.',
    );
  }
}
