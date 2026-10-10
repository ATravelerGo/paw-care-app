import 'package:dio/dio.dart';

import '../auth/auth_session_invalidator.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

final class UnauthorizedInterceptor extends Interceptor {
  UnauthorizedInterceptor({
    required this.tokenStorage,
    required this.sessionInvalidator,
  });

  final TokenStorage tokenStorage;
  final AuthSessionInvalidator sessionInvalidator;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final isPublicRequest =
        err.requestOptions.extra[AuthInterceptor.skipAuthKey] == true;

    if (isUnauthorized && !isPublicRequest) {
      Object? cleanupError;
      try {
        await tokenStorage.deleteAccessToken();
      } on Object catch (error) {
        cleanupError = error;
      }
      sessionInvalidator.invalidate(cleanupError: cleanupError);
    }

    handler.next(err);
  }
}
