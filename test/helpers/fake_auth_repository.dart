import 'package:paw_care_app/core/storage/token_storage.dart';
import 'package:paw_care_app/features/auth/domain/models/auth_user.dart';
import 'package:paw_care_app/features/auth/domain/repositories/auth_repository.dart';

final class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    required this.user,
    this.tokenStorage,
    this.currentUserError,
    this.authenticationError,
    this.logoutError,
  });

  final AuthUser user;
  final TokenStorage? tokenStorage;
  final Object? currentUserError;
  final Object? authenticationError;
  final Object? logoutError;

  int getCurrentUserCalls = 0;
  int loginCalls = 0;
  int registerCalls = 0;
  int logoutCalls = 0;
  String? lastEmail;
  String? lastPassword;
  String? lastNickname;

  @override
  Future<AuthUser> getCurrentUser() async {
    getCurrentUserCalls++;
    final error = currentUserError;
    if (error != null) throw error;
    return user;
  }

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    lastEmail = email;
    lastPassword = password;
    final error = authenticationError;
    if (error != null) throw error;
    return user;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    final error = logoutError;
    if (error != null) throw error;
    await tokenStorage?.deleteAccessToken();
  }

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
    required String nickname,
  }) async {
    registerCalls++;
    lastEmail = email;
    lastPassword = password;
    lastNickname = nickname;
    final error = authenticationError;
    if (error != null) throw error;
    return user;
  }
}
