import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _userInfoKey = 'user_info';

  Future<void> saveToken(String token) async {
    await _storage.write(
      key: _accessTokenKey,
      value: token,
    );
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<void> saveUserInfo(String userJson) async {
    await _storage.write(
      key: _userInfoKey,
      value: userJson,
    );
  }

  Future<String?> getUserInfo() async {
    return await _storage.read(key: _userInfoKey);
  }

  Future<void> clearAuthData() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _userInfoKey);
  }

  Future<void> deleteToken() async {
    await clearAuthData();
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}