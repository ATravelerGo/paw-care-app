import 'package:dio/dio.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../../domain/models/auth_user.dart';
import '../models/auth_response.dart';

abstract interface class AuthRemoteDataSource {
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String nickname,
  });

  Future<AuthResponse> login({required String email, required String password});

  Future<AuthUser> getCurrentUser();
}

final class ApiAuthRemoteDataSource implements AuthRemoteDataSource {
  ApiAuthRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      'auth/register',
      data: {'email': email, 'password': password, 'nickname': nickname},
      options: Options(extra: const {AuthInterceptor.skipAuthKey: true}),
    );
    return _decodeAuthResponse(response.data);
  }

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      'auth/login',
      data: {'email': email, 'password': password},
      options: Options(extra: const {AuthInterceptor.skipAuthKey: true}),
    );
    return _decodeAuthResponse(response.data);
  }

  @override
  Future<AuthUser> getCurrentUser() async {
    final response = await _apiClient.get<Map<String, dynamic>>('auth/me');
    return _decodeCurrentUser(response.data);
  }

  AuthResponse _decodeAuthResponse(Map<String, dynamic>? data) {
    try {
      if (data == null) {
        throw const FormatException('Response body is empty.');
      }
      return AuthResponse.fromJson(data);
    } on FormatException catch (error) {
      throw UnexpectedException('认证响应格式错误', cause: error);
    }
  }

  AuthUser _decodeCurrentUser(Map<String, dynamic>? data) {
    try {
      if (data == null) {
        throw const FormatException('Response body is empty.');
      }
      return AuthUserJson.fromJson(data);
    } on FormatException catch (error) {
      throw UnexpectedException('用户信息响应格式错误', cause: error);
    }
  }
}
