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

  testWidgets('creates a conversation and receives an AI reply', (
    tester,
  ) async {
    final storage = SecureTokenStorage();
    await storage.deleteAccessToken();
    await tester.pumpWidget(_testApp(config));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.enterText(find.byKey(const Key('login_email_field')), email);
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      password,
    );
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    await tester.tap(find.text('创建宠物档案'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('pet_name_field')), 'AI 测试猫');
    await tester.tap(find.byKey(const Key('save_pet_button')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(_testApp(config));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('nav_ai')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('new_conversation_button')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 2)),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 2)),
    );
    await tester.pumpAndSettle();
    expect(find.text('创建会话失败，请稍后重试。'), findsNothing);
    expect(find.text('无法加载这段会话。'), findsNothing);
    expect(find.byKey(const Key('chat_input_field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('chat_input_field')),
      '请简短地问候一下。',
    );
    await tester.tap(find.byKey(const Key('chat_send_button')));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 10)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('user_message')), findsOneWidget);
    expect(find.byKey(const Key('assistant_message')), findsOneWidget);
    expect(find.text('消息发送失败'), findsNothing);

    await tester.tap(find.byTooltip('返回会话列表'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('删除会话'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('nav_home')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.text('AI 测试猫'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI 测试猫'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除宠物档案'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await storage.deleteAccessToken();
  });
}

Widget _testApp(AppConfig config) {
  return ProviderScope(
    overrides: [appConfigProvider.overrideWithValue(config)],
    child: const PawCareApp(),
  );
}
