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

  testWidgets('creates, filters, edits, and deletes a health record', (
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
    await tester.enterText(find.byKey(const Key('pet_name_field')), '健康测试猫');
    await tester.tap(find.byKey(const Key('save_pet_button')));
    await _waitForNetwork(tester);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(_testApp(config));
    await _waitForNetwork(tester);
    await tester.tap(find.byKey(const Key('nav_health')));
    await _waitForNetwork(tester);

    await tester.tap(find.byKey(const Key('add_health_record_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('health_record_title')),
      '偶尔咳嗽',
    );
    await tester.enterText(
      find.byKey(const Key('health_record_description')),
      '今天上午轻微咳嗽两次',
    );
    await tester.tap(find.byKey(const Key('save_health_record_button')));
    await _waitForNetwork(tester);
    expect(find.text('偶尔咳嗽'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(ChoiceChip, '疫苗'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.text('没有符合条件的记录'), findsOneWidget);
    await tester.tap(find.text('清除筛选'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('偶尔咳嗽'));
    await tester.pumpAndSettle();
    expect(find.text('今天上午轻微咳嗽两次'), findsOneWidget);
    await tester.tap(find.byTooltip('编辑记录'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('health_record_description')),
      '下午没有继续咳嗽',
    );
    await tester.tap(find.byKey(const Key('save_health_record_button')));
    await _waitForNetwork(tester);
    expect(find.textContaining('下午没有继续咳嗽'), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await _waitForNetwork(tester);
    expect(find.text('还没有健康记录'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav_home')));
    await _waitForNetwork(tester);
    await tester.tap(find.text('健康测试猫'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('健康测试猫'));
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

Widget _testApp(AppConfig config) => ProviderScope(
  overrides: [appConfigProvider.overrideWithValue(config)],
  child: const PawCareApp(),
);
