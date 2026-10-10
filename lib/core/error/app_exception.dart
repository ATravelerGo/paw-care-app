sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause});
}

final class RequestTimeoutException extends AppException {
  const RequestTimeoutException(super.message, {super.cause});
}

final class RequestCancelledException extends AppException {
  const RequestCancelledException(super.message, {super.cause});
}

final class ApiException extends AppException {
  const ApiException(
    super.message, {
    required this.statusCode,
    this.responseData,
    super.cause,
  });

  final int? statusCode;
  final Object? responseData;
}

final class UnexpectedException extends AppException {
  const UnexpectedException(super.message, {super.cause});
}

final class SecureStorageException extends AppException {
  const SecureStorageException(super.message, {super.cause});
}
