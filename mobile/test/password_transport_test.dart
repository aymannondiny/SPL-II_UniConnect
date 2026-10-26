import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/data/services/auth_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registration, login and reset preserve the exact password', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final captured = <Map<String, dynamic>>[];
    final interceptor = InterceptorsWrapper(
      onRequest: (options, handler) {
        captured.add(Map<String, dynamic>.from(options.data as Map));
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: {'message': 'ok', 'token': 'test-session'},
          ),
        );
      },
    );
    final dio = DioClient().dio;
    dio.interceptors.add(interceptor);
    addTearDown(() => dio.interceptors.remove(interceptor));
    final service = AuthApiService();
    const password = ' reef violet lantern otter ';
    await service.register(
      fullName: 'Test User',
      email: 'test@iut-dhaka.edu',
      password: password,
      role: 'STUDENT',
    );
    await service.login(email: 'test@iut-dhaka.edu', password: password);
    await service.resetPassword(token: 'test-token', newPassword: password);
    expect(captured[0]['password'], password);
    expect(captured[1]['password'], password);
    expect(captured[2]['newPassword'], password);
  });
}
