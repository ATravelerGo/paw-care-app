import '../models/auth_user.dart';

abstract interface class AuthRepository {
  Future<AuthUser> register({
    required String email,
    required String password,
    required String nickname,
  });

  Future<AuthUser> login({required String email, required String password});

  Future<AuthUser> getCurrentUser();

  Future<void> logout();
}
