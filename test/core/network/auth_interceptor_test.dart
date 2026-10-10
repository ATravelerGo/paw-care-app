import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care_app/core/network/auth_interceptor.dart';

import '../../helpers/in_memory_token_storage.dart';

void main() {
  late Dio dio;
  late InMemoryTokenStorage tokenStorage;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.pawcare.example'));
    tokenStorage = InMemoryTokenStorage();
    dio.interceptors.add(AuthInterceptor(tokenStorage: tokenStorage));
  });

  Future<RequestOptions> captureRequest({Options? options}) async {
    late RequestOptions capturedOptions;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (requestOptions, handler) {
          capturedOptions = requestOptions;
          handler.resolve(
            Response<void>(requestOptions: requestOptions, statusCode: 204),
          );
        },
      ),
    );

    await dio.get<void>('/pets', options: options);
    return capturedOptions;
  }

  test('adds the saved access token to protected requests', () async {
    tokenStorage.token = 'test-token';

    final request = await captureRequest();

    expect(request.headers['Authorization'], 'Bearer test-token');
  });

  test('does not add Authorization when no token exists', () async {
    final request = await captureRequest();

    expect(request.headers, isNot(contains('Authorization')));
  });

  test('allows public endpoints to skip authentication', () async {
    tokenStorage.token = 'test-token';

    final request = await captureRequest(
      options: Options(extra: {AuthInterceptor.skipAuthKey: true}),
    );

    expect(request.headers, isNot(contains('Authorization')));
  });

  test(
    'does not overwrite an explicitly provided Authorization header',
    () async {
      tokenStorage.token = 'stored-token';

      final request = await captureRequest(
        options: Options(headers: {'Authorization': 'Custom request-token'}),
      );

      expect(request.headers['Authorization'], 'Custom request-token');
    },
  );
}
