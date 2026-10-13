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

  testWidgets('AI health fact appears in the health record list', (
    tester,
  ) async {
    expect(email, isNotEmpty, reason: 'AUTH_TEST_EMAIL is required.');
    expect(password, isNotEmpty, reason: 'AUTH_TEST_PASSWORD is required.');

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
    await _waitForNetwork(tester);

    await tester.tap(find.text('创建宠物档案'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('pet_name_field')), 'MVP 测试咪咪');
    await tester.tap(find.byKey(const Key('save_pet_button')));
    await _waitForNetwork(tester);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(_testApp(config));
    await _waitForNetwork(tester);
    await tester.tap(find.byKey(const Key('nav_ai')));
    await _waitForNetwork(tester);
    await tester.tap(find.byKey(const Key('new_conversation_button')));
    await _waitForNetwork(tester);
    await _waitForNetwork(tester);

    await tester.enterText(
      find.byKey(const Key('chat_input_field')),
      '咪咪今天吐了两次，请帮我记录这个健康情况并给出简短建议。',
    );
    await tester.tap(find.byKey(const Key('chat_send_button')));
    await _waitForAssistant(tester);
    expect(find.byKey(const Key('assistant_message')), findsOneWidget);
    expect(find.text('消息发送失败'), findsNothing);

    await tester.tap(find.byTooltip('返回会话列表'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('删除会话'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await _waitForNetwork(tester);

    await tester.tap(find.byKey(const Key('nav_health')));
    await _waitForNetwork(tester);
    expect(find.byKey(const Key('health_record_card')), findsWidgets);

    await tester.tap(find.byType(PopupMenuButton<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await _waitForNetwork(tester);

    await tester.tap(find.byKey(const Key('nav_home')));
    await _waitForNetwork(tester);
    await tester.tap(find.text('MVP 测试咪咪'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MVP 测试咪咪'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除宠物档案'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await _waitForNetwork(tester);
    await storage.deleteAccessToken();
  });
}

Future<void> _waitForNetwork(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
  await tester.pumpAndSettle();
}

Future<void> _waitForAssistant(WidgetTester tester) async {
  for (var attempt = 0; attempt < 60; attempt++) {
    await tester.pump();
    if (find.byKey(const Key('assistant_message')).evaluate().isNotEmpty) {
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
  }
  await tester.pumpAndSettle();
}

Widget _testApp(AppConfig config) => ProviderScope(
  overrides: [appConfigProvider.overrideWithValue(config)],
  child: const PawCareApp(),
);
