import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';

class AuthApiService {
  final Dio _dio = DioClient().dio;
  final SecureStorageService _storage = SecureStorageService();

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(_extractMessage(response.data, 'Login failed'));
      }

      final data = response.data;

      final token = data['token'] ??
          data['accessToken'] ??
          data['access_token'] ??
          data['jwt'];

      if (token == null) {
        throw Exception('Login successful but token not found');
      }

      await _storage.saveToken(token.toString());
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String userType,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'fullName': fullName,
          'email': email,
          'password': password,
          'userType': userType,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(_extractMessage(response.data, 'Registration failed'));
      }
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> verifyEmail({
    required String token,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.verifyEmail,
        queryParameters: {
          'token': token,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(_extractMessage(response.data, 'Email verification failed'));
      }
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.forgotPassword,
        data: {
          'email': email,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(_extractMessage(response.data, 'Failed to send reset email'));
      }
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.resetPassword,
        data: {
          'token': token,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(_extractMessage(response.data, 'Password reset failed'));
      }
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> logout() async {
    await _storage.deleteToken();
  }

  Future<String?> getSavedToken() async {
    return await _storage.getToken();
  }

  String _extractErrorMessage(DioException e) {
    return _extractMessage(e.response?.data, e.message ?? 'Something went wrong');
  }

  String _extractMessage(dynamic data, String fallback) {
    if (data is Map<String, dynamic>) {
      return data['message'] ??
          data['error'] ??
          data['detail'] ??
          data['statusMessage'] ??
          fallback;
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    return fallback;
  }
}