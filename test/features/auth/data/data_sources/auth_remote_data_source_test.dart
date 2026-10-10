import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care_app/core/auth/auth_session_invalidator.dart';
import 'package:paw_care_app/core/config/app_config.dart';
import 'package:paw_care_app/core/error/app_exception.dart';
import 'package:paw_care_app/core/network/api_client.dart';
import 'package:paw_care_app/core/network/auth_interceptor.dart';
import 'package:paw_care_app/features/auth/data/data_sources/auth_remote_data_source.dart';

import '../../../../helpers/in_memory_token_storage.dart';

void main() {
  late Dio dio;
  late ApiAuthRemoteDataSource dataSource;
  late RequestOptions capturedRequest;

  setUp(() {
    dio = Dio();
    final apiClient = ApiClient(
      config: AppConfig.fromValues(
        environmentName: 'dev',
        apiBaseUrl: 'https://api.pawcare.example/api',
      ),
      tokenStorage: InMemoryTokenStorage('stored-token'),
      sessionInvalidator: AuthSessionInvalidator(),
      dio: dio,
    );
    dataSource = ApiAuthRemoteDataSource(apiClient);
  });

  test(
    'registers through the public endpoint and parses its response',
    () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedRequest = options;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'access_token': 'new-token',
                  'user': {
                    'id': 'user-id',
                    'email': 'user@example.com',
                    'nickname': '小陈',
                    'avatarUrl': null,
                  },
                },
              ),
            );
          },
        ),
      );

      final response = await dataSource.register(
        email: 'user@example.com',
        password: '123456',
        nickname: '小陈',
      );

      expect(capturedRequest.uri.path, '/api/auth/register');
      expect(capturedRequest.headers['Authorization'], isNull);
      expect(capturedRequest.extra[AuthInterceptor.skipAuthKey], isTrue);
      expect(capturedRequest.data, {
        'email': 'user@example.com',
        'password': '123456',
        'nickname': '小陈',
      });
      expect(response.accessToken, 'new-token');
      expect(response.user.id, 'user-id');
    },
  );

  test('loads the current user with the stored token', () async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'id': 'user-id',
                'email': 'user@example.com',
                'nickname': null,
                'avatarUrl': null,
              },
            ),
          );
        },
      ),
    );

    final user = await dataSource.getCurrentUser();

    expect(capturedRequest.uri.path, '/api/auth/me');
    expect(capturedRequest.headers['Authorization'], 'Bearer stored-token');
    expect(user.id, 'user-id');
    expect(user.nickname, isNull);
  });

  test('converts an invalid response body into an app exception', () async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: {'access_token': 'token'},
            ),
          );
        },
      ),
    );

    await expectLater(
      dataSource.login(email: 'user@example.com', password: '123456'),
      throwsA(
        isA<UnexpectedException>().having(
          (error) => error.message,
          'message',
          '认证响应格式错误',
        ),
      ),
    );
  });
}
