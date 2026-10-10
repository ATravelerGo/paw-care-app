import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care_app/app/app.dart';
import 'package:paw_care_app/app/app_providers.dart';
import 'package:paw_care_app/core/config/app_config.dart';
import 'package:paw_care_app/features/auth/application/auth_providers.dart';
import 'package:paw_care_app/features/auth/domain/models/auth_user.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/in_memory_token_storage.dart';

void main() {
  testWidgets('redirects between home and login when the session changes', (
    tester,
  ) async {
    final tokenStorage = InMemoryTokenStorage('access-token');
    final authRepository = FakeAuthRepository(
      user: const AuthUser(
        id: 'user-id',
        email: 'user@example.com',
        nickname: '小陈',
        avatarUrl: null,
      ),
      tokenStorage: tokenStorage,
    );
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig.fromValues(
            environmentName: 'dev',
            apiBaseUrl: 'https://api.pawcare.example',
          ),
        ),
        tokenStorageProvider.overrideWithValue(tokenStorage),
        authRepositoryProvider.overrideWithValue(authRepository),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PawCareApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('logout_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('logout_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_email_field')), findsOneWidget);
    expect(authRepository.logoutCalls, 1);
  });
}
