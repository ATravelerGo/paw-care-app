import '../../../../core/storage/token_storage.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../data_sources/auth_remote_data_source.dart';
import '../models/auth_response.dart';

final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource, this._tokenStorage);

  final AuthRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final response = await _remoteDataSource.register(
      email: email,
      password: password,
      nickname: nickname,
    );
    return _establishSession(response);
  }

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _remoteDataSource.login(
      email: email,
      password: password,
    );
    return _establishSession(response);
  }

  @override
  Future<AuthUser> getCurrentUser() => _remoteDataSource.getCurrentUser();

  @override
  Future<void> logout() => _tokenStorage.deleteAccessToken();

  Future<AuthUser> _establishSession(AuthResponse response) async {
    await _tokenStorage.saveAccessToken(response.accessToken);
    return response.user;
  }
}
