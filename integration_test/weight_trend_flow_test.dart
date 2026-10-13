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

  testWidgets('creates weight records and displays their trend', (
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
    await tester.enterText(find.byKey(const Key('pet_name_field')), '体重趋势测试猫');
    await tester.tap(find.byKey(const Key('save_pet_button')));
    await _waitForNetwork(tester);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(_testApp(config));
    await _waitForNetwork(tester);
    await tester.tap(find.byKey(const Key('nav_health')));
    await _waitForNetwork(tester);

    await _createWeightRecord(tester, title: '第一次称重', value: '5.0 kg');
    await _createWeightRecord(tester, title: '第二次称重', value: '5.2 kg');

    await tester.tap(find.byKey(const Key('weight_trend_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('weight_trend_chart')), findsOneWidget);
    expect(find.byKey(const Key('weight_range_selector')), findsOneWidget);
    expect(find.text('5.2 kg'), findsWidgets);

    await tester.tap(find.byKey(const Key('app_back_button')));
    await tester.pumpAndSettle();
    await _deleteFirstVisibleRecord(tester);
    await _deleteFirstVisibleRecord(tester);

    await tester.tap(find.byKey(const Key('nav_home')));
    await _waitForNetwork(tester);
    await tester.tap(find.text('体重趋势测试猫'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('体重趋势测试猫'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除宠物档案'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await _waitForNetwork(tester);
    await storage.deleteAccessToken();
  });
}

Future<void> _createWeightRecord(
  WidgetTester tester, {
  required String title,
  required String value,
}) async {
  await tester.tap(find.byKey(const Key('add_health_record_button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('health_record_type')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('体重').last);
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('health_record_title')), title);
  await tester.enterText(
    find.byKey(const Key('health_record_description')),
    value,
  );
  await tester.tap(find.byKey(const Key('save_health_record_button')));
  await _waitForNetwork(tester);
  expect(find.text(title), findsOneWidget);
}

Future<void> _deleteFirstVisibleRecord(WidgetTester tester) async {
  await tester.tap(find.byType(PopupMenuButton<String>).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('删除'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('删除'));
  await _waitForNetwork(tester);
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
