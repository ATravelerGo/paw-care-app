import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care_app/core/auth/auth_session_invalidator.dart';
import 'package:paw_care_app/core/network/auth_interceptor.dart';
import 'package:paw_care_app/core/network/unauthorized_interceptor.dart';

import '../../helpers/in_memory_token_storage.dart';

void main() {
  test(
    'clears the token and invalidates the session after a protected 401',
    () async {
      final tokenStorage = InMemoryTokenStorage('expired-token');
      final invalidator = AuthSessionInvalidator();
      addTearDown(invalidator.dispose);
      var invalidationCount = 0;
      invalidator.addListener(() => invalidationCount++);
      final dio = _unauthorizedDio(tokenStorage, invalidator);

      await expectLater(
        dio.get<void>('/protected'),
        throwsA(isA<DioException>()),
      );

      expect(tokenStorage.token, isNull);
      expect(invalidationCount, 1);
    },
  );

  test('does not invalidate the session for a public endpoint 401', () async {
    final tokenStorage = InMemoryTokenStorage('existing-token');
    final invalidator = AuthSessionInvalidator();
    addTearDown(invalidator.dispose);
    var invalidationCount = 0;
    invalidator.addListener(() => invalidationCount++);
    final dio = _unauthorizedDio(tokenStorage, invalidator);

    await expectLater(
      dio.post<void>(
        '/auth/login',
        options: Options(extra: const {AuthInterceptor.skipAuthKey: true}),
      ),
      throwsA(isA<DioException>()),
    );

    expect(tokenStorage.token, 'existing-token');
    expect(invalidationCount, 0);
  });
}

Dio _unauthorizedDio(
  InMemoryTokenStorage tokenStorage,
  AuthSessionInvalidator invalidator,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.pawcare.example'));
  dio.httpClientAdapter = _UnauthorizedAdapter();
  dio.interceptors.add(AuthInterceptor(tokenStorage: tokenStorage));
  dio.interceptors.add(
    UnauthorizedInterceptor(
      tokenStorage: tokenStorage,
      sessionInvalidator: invalidator,
    ),
  );
  return dio;
}

final class _UnauthorizedAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"message":"Unauthorized"}',
      401,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
