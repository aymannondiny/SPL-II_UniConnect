import 'package:flutter/material.dart';

import '../../../../data/services/auth_api_service.dart';

class VerifyEmailProvider extends ChangeNotifier {
  final AuthApiService _authApiService = AuthApiService();

  bool isLoading = false;
  bool isSuccess = false;
  String? successMessage;
  String? errorMessage;

  Future<void> verifyEmail(String token) async {
    if (token.trim().isEmpty) {
      isLoading = false;
      isSuccess = false;
      successMessage = null;
      errorMessage = 'Verification token is missing.';
      notifyListeners();
      return;
    }

    isLoading = true;
    isSuccess = false;
    successMessage = null;
    errorMessage = null;
    notifyListeners();

    try {
      final message = await _authApiService.verifyEmail(
        token: token.trim(),
      );

      isLoading = false;
      isSuccess = true;
      successMessage = message;
      errorMessage = null;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      isSuccess = false;
      successMessage = null;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> resendVerificationEmail(String email) async {
    try {
      await _authApiService.resendVerificationEmail(
        email: email.trim(),
      );

      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void reset() {
    isLoading = false;
    isSuccess = false;
    successMessage = null;
    errorMessage = null;
    notifyListeners();
  }
}