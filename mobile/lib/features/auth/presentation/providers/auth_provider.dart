import 'package:flutter/material.dart';

import '../../../../data/services/auth_api_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthApiService _authApiService = AuthApiService();

  bool isLoading = false;
  bool isSuccess = false;
  String? successMessage;
  String? errorMessage;

  Future<bool> registerUser({
    String? fullName,
    String? name,
    required String email,
    required String password,
    String? role,
    String? userType,
    String? selectedRole,
    String? confirmPassword,
  }) async {
    final resolvedName = (fullName ?? name ?? '').trim();
    final resolvedRole = (role ?? userType ?? selectedRole ?? '').trim();

    if (resolvedName.isEmpty) {
      errorMessage = 'Full name is required.';
      notifyListeners();
      return false;
    }

    if (email.trim().isEmpty) {
      errorMessage = 'Email is required.';
      notifyListeners();
      return false;
    }

    if (password.trim().isEmpty) {
      errorMessage = 'Password is required.';
      notifyListeners();
      return false;
    }

    if (resolvedRole.isEmpty) {
      errorMessage = 'Role is required.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    isSuccess = false;
    successMessage = null;
    errorMessage = null;
    notifyListeners();

    try {
      final message = await _authApiService.register(
        fullName: resolvedName,
        email: email.trim(),
        password: password.trim(),
        role: resolvedRole,
      );

      isLoading = false;
      isSuccess = true;
      successMessage = message;
      errorMessage = null;
      notifyListeners();

      return true;
    } catch (e) {
      isLoading = false;
      isSuccess = false;
      successMessage = null;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();

      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    return registerUser(
      fullName: fullName,
      email: email,
      password: password,
      role: role,
    );
  }

  void reset() {
    isLoading = false;
    isSuccess = false;
    successMessage = null;
    errorMessage = null;
    notifyListeners();
  }
}