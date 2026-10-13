import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paw_care_app/app/app.dart';
import 'package:paw_care_app/app/app_providers.dart';
import 'package:paw_care_app/core/config/app_config.dart';
import 'package:paw_care_app/core/storage/secure_token_storage.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const email = String.fromEnvironment('AUTH_TEST_EMAIL');
  const password = String.fromEnvironment('AUTH_TEST_PASSWORD');
  final config = AppConfig.fromValues(
    environmentName: 'dev',
    apiBaseUrl: 'http://127.0.0.1:3000/api',
  );

  testWidgets('logs in, restores the session, and logs out', (tester) async {
    expect(email, isNotEmpty, reason: 'AUTH_TEST_EMAIL is required.');
    expect(password, isNotEmpty, reason: 'AUTH_TEST_PASSWORD is required.');

    final tokenStorage = SecureTokenStorage();
    await tokenStorage.deleteAccessToken();

    await tester.pumpWidget(_testApp(config));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('login_email_field')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('login_email_field')), email);
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      password,
    );
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('先创建第一只宠物吧'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(_testApp(config));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('先创建第一只宠物吧'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav_health')));
    await tester.pumpAndSettle();
    expect(find.text('健康记录即将开放'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav_ai')));
    await tester.pumpAndSettle();
    expect(find.text('PawCare AI 即将开放'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav_gallery')));
    await tester.pumpAndSettle();
    expect(find.text('宠物相册即将开放'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav_profile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('logout_button')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('login_email_field')), findsOneWidget);
    expect(await tokenStorage.readAccessToken(), isNull);
  });
}

Widget _testApp(AppConfig config) {
  return ProviderScope(
    overrides: [appConfigProvider.overrideWithValue(config)],
    child: const PawCareApp(),
  );
}
