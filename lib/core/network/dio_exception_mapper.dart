import 'package:dio/dio.dart';

import '../error/app_exception.dart';

abstract final class DioExceptionMapper {
  static AppException map(DioException exception) {
    if (exception.error case final AppException appException) {
      return appException;
    }

    return switch (exception.type) {
      DioExceptionType.cancel => RequestCancelledException(
        '请求已取消',
        cause: exception,
      ),
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => RequestTimeoutException(
        '请求超时，请稍后重试',
        cause: exception,
      ),
      DioExceptionType.badResponse => _mapBadResponse(exception),
      DioExceptionType.badCertificate => NetworkException(
        '无法建立安全连接',
        cause: exception,
      ),
      DioExceptionType.connectionError => NetworkException(
        '无法连接服务器，请检查网络',
        cause: exception,
      ),
      DioExceptionType.unknown when exception.response != null =>
        _mapBadResponse(exception),
      DioExceptionType.unknown => NetworkException(
        '网络请求失败，请稍后重试',
        cause: exception,
      ),
    };
  }

  static ApiException _mapBadResponse(DioException exception) {
    final response = exception.response;
    final statusCode = response?.statusCode;

    return ApiException(
      _extractMessage(response?.data, statusCode),
      statusCode: statusCode,
      responseData: response?.data,
      cause: exception,
    );
  }

  static String _extractMessage(Object? data, int? statusCode) {
    if (data case {'message': final Object? message}) {
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }

      if (message is List) {
        final messages = message.whereType<String>().where(
          (item) => item.trim().isNotEmpty,
        );
        if (messages.isNotEmpty) {
          return messages.join('；');
        }
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    return statusCode == null ? '请求失败' : '请求失败（$statusCode）';
  }
}
