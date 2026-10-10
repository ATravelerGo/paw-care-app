import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care_app/core/error/app_exception.dart';
import 'package:paw_care_app/core/network/dio_exception_mapper.dart';

void main() {
  final requestOptions = RequestOptions(path: '/pets');

  test('keeps the server status and message for bad responses', () {
    final exception = DioException(
      requestOptions: requestOptions,
      type: DioExceptionType.badResponse,
      response: Response<Object?>(
        requestOptions: requestOptions,
        statusCode: 422,
        data: {
          'message': ['name should not be empty', 'species is invalid'],
        },
      ),
    );

    final result = DioExceptionMapper.map(exception);

    expect(result, isA<ApiException>());
    final apiException = result as ApiException;
    expect(apiException.statusCode, 422);
    expect(apiException.message, 'name should not be empty；species is invalid');
  });

  test('maps connection errors without exposing Dio details', () {
    final result = DioExceptionMapper.map(
      DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionError,
      ),
    );

    expect(result, isA<NetworkException>());
    expect(result.message, '无法连接服务器，请检查网络');
  });

  test('maps cancelled requests separately', () {
    final result = DioExceptionMapper.map(
      DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.cancel,
      ),
    );

    expect(result, isA<RequestCancelledException>());
  });
}
