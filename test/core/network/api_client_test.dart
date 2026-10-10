import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care_app/core/auth/auth_session_invalidator.dart';
import 'package:paw_care_app/core/config/app_config.dart';
import 'package:paw_care_app/core/error/app_exception.dart';
import 'package:paw_care_app/core/network/api_client.dart';

import '../../helpers/in_memory_token_storage.dart';

void main() {
  late Dio dio;
  late ApiClient client;

  setUp(() {
    dio = Dio();
    client = ApiClient(
      config: AppConfig.fromValues(
        environmentName: 'dev',
        apiBaseUrl: 'https://api.pawcare.example/api',
      ),
      tokenStorage: InMemoryTokenStorage(),
      sessionInvalidator: AuthSessionInvalidator(),
      dio: dio,
    );
  });

  test('configures the shared Dio instance', () {
    expect(dio.options.baseUrl, 'https://api.pawcare.example/api/');
    expect(dio.options.connectTimeout, const Duration(seconds: 10));
    expect(dio.options.sendTimeout, const Duration(seconds: 30));
    expect(dio.options.receiveTimeout, const Duration(seconds: 30));
    expect(dio.options.headers['Accept'], 'application/json');
  });

  test('returns a successful response without changing its body', () async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: {'status': 'ok'},
            ),
          );
        },
      ),
    );

    final response = await client.get<Map<String, dynamic>>('health');

    expect(response.statusCode, 200);
    expect(response.data, {'status': 'ok'});
    expect(response.requestOptions.uri.path, '/api/health');
  });

  test('maps Dio transport failures to app exceptions', () async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionTimeout,
            ),
          );
        },
      ),
    );

    await expectLater(
      client.get<Object?>('health'),
      throwsA(isA<RequestTimeoutException>()),
    );
  });
}
