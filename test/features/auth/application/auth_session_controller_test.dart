import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care_app/core/auth/auth_session_invalidator.dart';
import 'package:paw_care_app/core/error/app_exception.dart';
import 'package:paw_care_app/features/auth/application/auth_session_controller.dart';
import 'package:paw_care_app/features/auth/domain/models/auth_user.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/in_memory_token_storage.dart';

void main() {
  const user = AuthUser(
    id: 'user-id',
    email: 'user@example.com',
    nickname: '小陈',
    avatarUrl: null,
  );

  test('restores an unauthenticated session when no token is stored', () async {
    final repository = FakeAuthRepository(user: user);
    final controller = AuthSessionController(
      authRepository: repository,
      tokenStorage: InMemoryTokenStorage(),
      sessionInvalidator: AuthSessionInvalidator(),
    );
    addTearDown(controller.dispose);

    await controller.restore();

    expect(controller.status, AuthSessionStatus.unauthenticated);
    expect(controller.currentUser, isNull);
    expect(controller.restoreError, isNull);
    expect(repository.getCurrentUserCalls, 0);
  });

  test('validates a stored token and restores its current user', () async {
    final repository = FakeAuthRepository(user: user);
    final controller = AuthSessionController(
      authRepository: repository,
      tokenStorage: InMemoryTokenStorage('stored-token'),
      sessionInvalidator: AuthSessionInvalidator(),
    );
    addTearDown(controller.dispose);

    await controller.restore();

    expect(controller.status, AuthSessionStatus.authenticated);
    expect(controller.currentUser, same(user));
    expect(controller.restoreError, isNull);
    expect(repository.getCurrentUserCalls, 1);
  });

  test('clears an invalid stored token after auth/me returns 401', () async {
    final tokenStorage = InMemoryTokenStorage('expired-token');
    final repository = FakeAuthRepository(
      user: user,
      tokenStorage: tokenStorage,
      currentUserError: const ApiException('登录状态已失效', statusCode: 401),
    );
    final controller = AuthSessionController(
      authRepository: repository,
      tokenStorage: tokenStorage,
      sessionInvalidator: AuthSessionInvalidator(),
    );
    addTearDown(controller.dispose);

    await controller.restore();

    expect(controller.status, AuthSessionStatus.unauthenticated);
    expect(controller.currentUser, isNull);
    expect(controller.restoreError, isNull);
    expect(repository.logoutCalls, 1);
    expect(tokenStorage.token, isNull);
  });

  test('keeps the token when session restoration fails temporarily', () async {
    final error = const NetworkException('无法连接服务器');
    final tokenStorage = InMemoryTokenStorage('stored-token');
    final repository = FakeAuthRepository(
      user: user,
      tokenStorage: tokenStorage,
      currentUserError: error,
    );
    final controller = AuthSessionController(
      authRepository: repository,
      tokenStorage: tokenStorage,
      sessionInvalidator: AuthSessionInvalidator(),
    );
    addTearDown(controller.dispose);

    await controller.restore();

    expect(controller.status, AuthSessionStatus.unauthenticated);
    expect(controller.restoreError, same(error));
    expect(tokenStorage.token, 'stored-token');
    expect(repository.logoutCalls, 0);
  });

  test('updates the current user after login succeeds', () async {
    final controller = AuthSessionController(
      authRepository: FakeAuthRepository(user: user),
      tokenStorage: InMemoryTokenStorage(),
      sessionInvalidator: AuthSessionInvalidator(),
    );
    addTearDown(controller.dispose);

    await controller.login(email: 'user@example.com', password: '123456');

    expect(controller.status, AuthSessionStatus.authenticated);
    expect(controller.currentUser, same(user));
    expect(controller.isAuthenticating, isFalse);
    expect(controller.authenticationError, isNull);
  });

  test('exposes an authentication error without creating a session', () async {
    final error = const ApiException('邮箱或密码错误', statusCode: 401);
    final controller = AuthSessionController(
      authRepository: FakeAuthRepository(
        user: user,
        authenticationError: error,
      ),
      tokenStorage: InMemoryTokenStorage(),
      sessionInvalidator: AuthSessionInvalidator(),
    );
    addTearDown(controller.dispose);

    await expectLater(
      controller.login(email: 'user@example.com', password: 'wrong-password'),
      throwsA(same(error)),
    );

    expect(controller.status, AuthSessionStatus.unknown);
    expect(controller.currentUser, isNull);
    expect(controller.isAuthenticating, isFalse);
    expect(controller.authenticationError, same(error));
  });

  test('clears the current user and token on logout', () async {
    final tokenStorage = InMemoryTokenStorage('stored-token');
    final repository = FakeAuthRepository(
      user: user,
      tokenStorage: tokenStorage,
    );
    final controller = AuthSessionController(
      authRepository: repository,
      tokenStorage: tokenStorage,
      sessionInvalidator: AuthSessionInvalidator(),
    );
    addTearDown(controller.dispose);
    await controller.restore();

    await controller.logout();

    expect(controller.status, AuthSessionStatus.unauthenticated);
    expect(controller.currentUser, isNull);
    expect(tokenStorage.token, isNull);
  });

  test(
    'leaves the authenticated state when the network invalidates it',
    () async {
      final invalidator = AuthSessionInvalidator();
      final controller = AuthSessionController(
        authRepository: FakeAuthRepository(user: user),
        tokenStorage: InMemoryTokenStorage(),
        sessionInvalidator: invalidator,
      );
      addTearDown(controller.dispose);
      await controller.login(email: 'user@example.com', password: '123456');

      invalidator.invalidate();

      expect(controller.status, AuthSessionStatus.unauthenticated);
      expect(controller.currentUser, isNull);
    },
  );
}
