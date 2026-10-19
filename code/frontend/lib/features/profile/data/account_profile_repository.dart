import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/authentication/model/current_account.dart';

class AccountProfileRepository {
  AccountProfileRepository(this.client, this.session);
  final ApiClient client;
  final SessionController session;

  Future<CurrentAccount> updateName(String name) async {
    try {
      final response = await client
          .patch(
            '/api/v1/auth/me',
            body: {'fullName': name},
            headers: {'Authorization': 'Bearer ${await session.accessToken()}'},
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 401) {
        session.expire();
        throw const AuthFailure(
          'Your session has ended. Please log in again.',
          sessionEnded: true,
        );
      }
      if (response.statusCode != 200) {
        final message = response.statusCode == 400
            ? 'Enter a name with 1 to 100 characters.'
            : 'Unable to update your account details. Please try again.';
        throw AuthFailure(message);
      }
      return CurrentAccount.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } on TimeoutException {
      throw const AuthFailure('The request timed out. Please try again.');
    } on http.ClientException {
      throw const AuthFailure(
        'Cannot reach UniConnect. Check your connection and retry.',
      );
    } on FormatException {
      throw const AuthFailure(
        'The server returned an invalid account response.',
      );
    }
  }
}
