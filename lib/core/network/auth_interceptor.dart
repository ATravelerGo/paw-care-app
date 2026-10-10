import 'package:dio/dio.dart';

import '../error/app_exception.dart';
import '../storage/token_storage.dart';

final class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.tokenStorage});

  static const skipAuthKey = 'skipAuth';
  static const _authorizationHeader = 'Authorization';

  final TokenStorage tokenStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuthKey] == true ||
        options.headers.containsKey(_authorizationHeader)) {
      handler.next(options);
      return;
    }

    try {
      final token = await tokenStorage.readAccessToken();
      if (token != null && token.trim().isNotEmpty) {
        options.headers[_authorizationHeader] = 'Bearer ${token.trim()}';
      }
      handler.next(options);
    } on AppException catch (error) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: error,
        ),
      );
    }
  }
}
