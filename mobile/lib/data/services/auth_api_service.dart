import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/secure_storage_service.dart';

class AuthApiService {
  final Dio _dio = DioClient().dio;
  final SecureStorageService _storage = SecureStorageService();

  Future<String> register({
    String? name,
    String? fullName,
    String? username,
    required String email,
    required String password,
    String? confirmPassword,
    String? phone,
    String? studentId,
    String? studentID,
    String? department,
    String? batch,
    String? semester,
    String? role,
  }) async {
    try {
      final data = <String, dynamic>{
        'email': email.trim(),
        'password': password.trim(),
      };

      void addIfNotEmpty(String key, String? value) {
        if (value != null && value.trim().isNotEmpty) {
          data[key] = value.trim();
        }
      }

      addIfNotEmpty('name', name ?? fullName ?? username);
      addIfNotEmpty('fullName', fullName);
      addIfNotEmpty('username', username);
      addIfNotEmpty('confirmPassword', confirmPassword);
      addIfNotEmpty('phone', phone);
      addIfNotEmpty('studentId', studentId ?? studentID);
      addIfNotEmpty('department', department);
      addIfNotEmpty('batch', batch);
      addIfNotEmpty('semester', semester);
      addIfNotEmpty('role', role);

      final response = await _dio.post(
        ApiConstants.register,
        data: data,
      );

      if (!_isSuccess(response.statusCode)) {
        throw Exception(
          _getMessage(response.data, 'Registration failed.'),
        );
      }

      await _saveAuthDataIfAvailable(
        response.data,
        fallbackEmail: email,
      );

      return _getMessage(
        response.data,
        'Registration successful. Please verify your email.',
      );
    } on DioException catch (e) {
      throw Exception(
        _getMessage(
          e.response?.data,
          'Network error. Please check backend connection.',
        ),
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'email': email.trim(),
          'password': password.trim(),
        },
      );

      if (!_isSuccess(response.statusCode)) {
        throw Exception(
          _getMessage(response.data, 'Login failed.'),
        );
      }

      final token = _findToken(response.data);

      if (token == null || token.isEmpty) {
        throw Exception('Login successful but token not found.');
      }

      await _storage.saveToken(token);

      final userInfo = _findUserInfo(response.data);

      if (userInfo != null) {
        await _storage.saveUserInfo(jsonEncode(userInfo));
      } else {
        await _storage.saveUserInfo(
          jsonEncode({
            'email': email.trim(),
          }),
        );
      }

      return _getMessage(response.data, 'Login successful.');
    } on DioException catch (e) {
      throw Exception(
        _getMessage(
          e.response?.data,
          'Network error. Please check backend connection.',
        ),
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<String> verifyEmail({
    String? email,
    String? token,
    String? verificationToken,
    String? emailToken,
    String? code,
    String? otp,
  }) async {
    try {
      final data = <String, dynamic>{};

      void addIfNotEmpty(String key, String? value) {
        if (value != null && value.trim().isNotEmpty) {
          data[key] = value.trim();
        }
      }

      final mainToken = token ?? verificationToken ?? emailToken ?? code ?? otp;

      addIfNotEmpty('email', email);
      addIfNotEmpty('token', mainToken);
      addIfNotEmpty('verificationToken', verificationToken);
      addIfNotEmpty('emailToken', emailToken);
      addIfNotEmpty('code', code);
      addIfNotEmpty('otp', otp);

      if (data.isEmpty) {
        throw Exception('Email verification data is missing.');
      }

      final response = await _dio.post(
        ApiConstants.verifyEmail,
        data: data,
      );

      if (!_isSuccess(response.statusCode)) {
        throw Exception(
          _getMessage(response.data, 'Email verification failed.'),
        );
      }

      await _saveAuthDataIfAvailable(
        response.data,
        fallbackEmail: email,
      );

      return _getMessage(
        response.data,
        'Email verified successfully.',
      );
    } on DioException catch (e) {
      throw Exception(
        _getMessage(
          e.response?.data,
          'Network error. Please check backend connection.',
        ),
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<String> resendVerificationEmail({
    String? email,
  }) async {
    try {
      if (email == null || email.trim().isEmpty) {
        throw Exception('Email is required.');
      }

      final response = await _dio.post(
        ApiConstants.resendVerificationEmail,
        data: {
          'email': email.trim(),
        },
      );

      if (!_isSuccess(response.statusCode)) {
        throw Exception(
          _getMessage(response.data, 'Failed to resend verification email.'),
        );
      }

      return _getMessage(
        response.data,
        'Verification email sent again. Please check your inbox.',
      );
    } on DioException catch (e) {
      throw Exception(
        _getMessage(
          e.response?.data,
          'Network error. Please check backend connection.',
        ),
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<String> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.forgotPassword,
        data: {
          'email': email.trim(),
        },
      );

      if (!_isSuccess(response.statusCode)) {
        throw Exception(
          _getMessage(response.data, 'Failed to send reset email.'),
        );
      }

      return _getMessage(
        response.data,
        'Password reset email sent. Please check your inbox.',
      );
    } on DioException catch (e) {
      throw Exception(
        _getMessage(
          e.response?.data,
          'Network error. Please check backend connection.',
        ),
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.resetPassword,
        data: {
          'token': token.trim(),
          'newPassword': newPassword.trim(),
        },
      );

      if (!_isSuccess(response.statusCode)) {
        throw Exception(
          _getMessage(response.data, 'Password reset failed.'),
        );
      }

      return _getMessage(
        response.data,
        'Password reset successful. Please login.',
      );
    } on DioException catch (e) {
      throw Exception(
        _getMessage(
          e.response?.data,
          'Network error. Please check backend connection.',
        ),
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    await _storage.clearAuthData();
  }

  Future<bool> isLoggedIn() async {
    return await _storage.hasToken();
  }

  Future<String?> getSavedToken() async {
    return await _storage.getToken();
  }

  Future<String?> getSavedUserInfo() async {
    return await _storage.getUserInfo();
  }

  Future<void> _saveAuthDataIfAvailable(
      dynamic data, {
        String? fallbackEmail,
      }) async {
    final token = _findToken(data);

    if (token != null && token.isNotEmpty) {
      await _storage.saveToken(token);
    }

    final userInfo = _findUserInfo(data);

    if (userInfo != null) {
      await _storage.saveUserInfo(jsonEncode(userInfo));
    } else if (fallbackEmail != null && fallbackEmail.trim().isNotEmpty) {
      await _storage.saveUserInfo(
        jsonEncode({
          'email': fallbackEmail.trim(),
        }),
      );
    }
  }

  bool _isSuccess(int? statusCode) {
    return statusCode != null && statusCode >= 200 && statusCode < 300;
  }

  String? _findToken(dynamic data) {
    if (data == null) return null;

    if (data is String) {
      if (data.startsWith('eyJ')) return data;
      return null;
    }

    if (data is Map) {
      final possibleKeys = [
        'token',
        'accessToken',
        'access_token',
        'jwt',
        'jwtToken',
        'authToken',
        'bearerToken',
      ];

      for (final key in possibleKeys) {
        final value = data[key];

        if (value is String && value.isNotEmpty) {
          return value;
        }
      }

      for (final value in data.values) {
        final foundToken = _findToken(value);

        if (foundToken != null && foundToken.isNotEmpty) {
          return foundToken;
        }
      }
    }

    if (data is List) {
      for (final value in data) {
        final foundToken = _findToken(value);

        if (foundToken != null && foundToken.isNotEmpty) {
          return foundToken;
        }
      }
    }

    return null;
  }

  Map<String, dynamic>? _findUserInfo(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);

      final possibleKeys = [
        'user',
        'currentUser',
        'profile',
        'userInfo',
      ];

      for (final key in possibleKeys) {
        final value = map[key];

        if (value is Map) {
          return Map<String, dynamic>.from(value);
        }
      }

      if (map['data'] is Map) {
        final nestedData = Map<String, dynamic>.from(map['data']);

        for (final key in possibleKeys) {
          final value = nestedData[key];

          if (value is Map) {
            return Map<String, dynamic>.from(value);
          }
        }

        return nestedData;
      }
    }

    return null;
  }

  String _getMessage(dynamic data, String defaultMessage) {
    if (data == null) return defaultMessage;

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);

      if (map['message'] != null) {
        return map['message'].toString();
      }

      if (map['error'] != null) {
        return map['error'].toString();
      }

      if (map['detail'] != null) {
        return map['detail'].toString();
      }

      if (map['errors'] is List) {
        return (map['errors'] as List).join('\n');
      }

      if (map['errors'] is Map) {
        final errors = map['errors'] as Map;
        return errors.values.join('\n');
      }

      if (map['validationErrors'] is Map) {
        final errors = map['validationErrors'] as Map;
        return errors.values.join('\n');
      }

      if (map['data'] is Map) {
        return _getMessage(map['data'], defaultMessage);
      }
    }

    return defaultMessage;
  }
}

  String? _findToken(dynamic data) {
    if (data == null) return null;

    if (data is String) {
      if (data.startsWith('eyJ')) return data;
      return null;
    }

    if (data is Map<String, dynamic>) {
      final possibleKeys = [
        'token',
        'accessToken',
        'access_token',
        'jwt',
        'jwtToken',
        'authToken',
        'bearerToken',
      ];

      for (final key in possibleKeys) {
        final value = data[key];

        if (value is String && value.isNotEmpty) {
          return value;
        }
      }

      for (final value in data.values) {
        final foundToken = _findToken(value);

        if (foundToken != null && foundToken.isNotEmpty) {
          return foundToken;
        }
      }
    }

    return null;
  }

  Map<String, dynamic>? _findUserInfo(dynamic data) {
    if (data == null) return null;

    if (data is Map<String, dynamic>) {
      final possibleKeys = [
        'user',
        'currentUser',
        'profile',
        'userInfo',
      ];

      for (final key in possibleKeys) {
        final value = data[key];

        if (value is Map<String, dynamic>) {
          return value;
        }
      }

      if (data['data'] is Map<String, dynamic>) {
        final nestedData = data['data'] as Map<String, dynamic>;

        for (final key in possibleKeys) {
          final value = nestedData[key];

          if (value is Map<String, dynamic>) {
            return value;
          }
        }

        return nestedData;
      }
    }

    return null;
  }

  String _getMessage(dynamic data, String defaultMessage) {
    if (data == null) return defaultMessage;

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      if (data['message'] != null) {
        return data['message'].toString();
      }

      if (data['error'] != null) {
        return data['error'].toString();
      }

      if (data['detail'] != null) {
        return data['detail'].toString();
      }

      if (data['errors'] is List) {
        return (data['errors'] as List).join('\n');
      }

      if (data['errors'] is Map) {
        final errors = data['errors'] as Map;
        return errors.values.join('\n');
      }

      if (data['validationErrors'] is Map) {
        final errors = data['validationErrors'] as Map;
        return errors.values.join('\n');
      }

      if (data['data'] is Map<String, dynamic>) {
        return _getMessage(data['data'], defaultMessage);
      }
    }

    return defaultMessage;
  }
