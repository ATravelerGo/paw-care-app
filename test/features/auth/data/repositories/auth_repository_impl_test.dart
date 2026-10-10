import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care_app/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:paw_care_app/features/auth/data/models/auth_response.dart';
import 'package:paw_care_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:paw_care_app/features/auth/domain/models/auth_user.dart';

import '../../../../helpers/in_memory_token_storage.dart';

void main() {
  const user = AuthUser(
    id: 'user-id',
    email: 'user@example.com',
    nickname: '小陈',
    avatarUrl: null,
  );

  test('saves the access token only after a successful login', () async {
    final tokenStorage = InMemoryTokenStorage();
    final repository = AuthRepositoryImpl(
      _FakeAuthRemoteDataSource(
        response: const AuthResponse(accessToken: 'new-token', user: user),
      ),
      tokenStorage,
    );

    final result = await repository.login(
      email: 'user@example.com',
      password: '123456',
    );

    expect(result, same(user));
    expect(tokenStorage.token, 'new-token');
  });

  test('does not replace the stored token when login fails', () async {
    final tokenStorage = InMemoryTokenStorage('existing-token');
    final repository = AuthRepositoryImpl(
      _FakeAuthRemoteDataSource(error: StateError('failed')),
      tokenStorage,
    );

    await expectLater(
      repository.login(email: 'user@example.com', password: 'wrong-password'),
      throwsStateError,
    );
    expect(tokenStorage.token, 'existing-token');
  });

  test('clears the access token on logout', () async {
    final tokenStorage = InMemoryTokenStorage('stored-token');
    final repository = AuthRepositoryImpl(
      _FakeAuthRemoteDataSource(
        response: const AuthResponse(accessToken: 'new-token', user: user),
      ),
      tokenStorage,
    );

    await repository.logout();

    expect(tokenStorage.token, isNull);
  });
}

final class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  _FakeAuthRemoteDataSource({this.response, this.error});

  final AuthResponse? response;
  final Object? error;

  @override
  Future<AuthUser> getCurrentUser() async => _result().user;

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async => _result();

  @override
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String nickname,
  }) async => _result();

  AuthResponse _result() {
    final failure = error;
    if (failure != null) throw failure;
    return response!;
  }
}
