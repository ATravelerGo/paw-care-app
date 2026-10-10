import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care_app/app/app.dart';
import 'package:paw_care_app/app/app_providers.dart';
import 'package:paw_care_app/core/config/app_config.dart';
import 'package:paw_care_app/core/error/app_exception.dart';
import 'package:paw_care_app/features/auth/application/auth_providers.dart';
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

  testWidgets('logs in with normalized form values', (tester) async {
    final repository = FakeAuthRepository(user: user);
    await _pumpApp(tester, repository);

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      '  USER@EXAMPLE.COM  ',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      '123456',
    );
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(repository.loginCalls, 1);
    expect(repository.lastEmail, 'user@example.com');
    expect(repository.lastPassword, '123456');
    expect(find.byKey(const Key('logout_button')), findsOneWidget);
  });

  testWidgets('shows the server message when login fails', (tester) async {
    final repository = FakeAuthRepository(
      user: user,
      authenticationError: const ApiException('邮箱或密码错误', statusCode: 401),
    );
    await _pumpApp(tester, repository);

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      '123456',
    );
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('邮箱或密码错误'), findsOneWidget);
    expect(find.text('登录'), findsWidgets);
  });

  testWidgets('validates password confirmation before registration', (
    tester,
  ) async {
    final repository = FakeAuthRepository(user: user);
    await _pumpApp(tester, repository);

    await tester.tap(find.byKey(const Key('open_register_button')));
    await tester.pumpAndSettle();
    expect(find.text('创建账号'), findsWidgets);

    await tester.enterText(
      find.byKey(const Key('register_nickname_field')),
      '  小陈  ',
    );
    await tester.enterText(
      find.byKey(const Key('register_email_field')),
      '  USER@EXAMPLE.COM  ',
    );
    await tester.enterText(
      find.byKey(const Key('register_password_field')),
      '123456',
    );
    await tester.enterText(
      find.byKey(const Key('register_confirm_password_field')),
      '654321',
    );

    final submitButton = find.byKey(const Key('register_submit_button'));
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();

    expect(find.text('两次输入的密码不一致'), findsOneWidget);
    expect(repository.registerCalls, 0);

    await tester.enterText(
      find.byKey(const Key('register_confirm_password_field')),
      '123456',
    );
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(repository.registerCalls, 1);
    expect(repository.lastEmail, 'user@example.com');
    expect(repository.lastNickname, '小陈');
    expect(find.byKey(const Key('logout_button')), findsOneWidget);
  });
}

Future<void> _pumpApp(
  WidgetTester tester,
  FakeAuthRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig.fromValues(
            environmentName: 'dev',
            apiBaseUrl: 'https://api.pawcare.example',
          ),
        ),
        tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        authRepositoryProvider.overrideWithValue(repository),
      ],
      child: const PawCareApp(),
    ),
  );
  await tester.pumpAndSettle();
}
