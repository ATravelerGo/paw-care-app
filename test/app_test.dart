import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care_app/app/app.dart';
import 'package:paw_care_app/app/app_providers.dart';
import 'package:paw_care_app/core/config/app_config.dart';
import 'package:paw_care_app/core/theme/app_colors.dart';

import 'helpers/in_memory_token_storage.dart';

void main() {
  testWidgets('PawCare app uses the project identity and theme', (
    tester,
  ) async {
    final config = AppConfig.fromValues(
      environmentName: 'prod',
      apiBaseUrl: 'https://api.pawcare.example',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        ],
        child: const PawCareApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_email_field')), findsOneWidget);
    expect(find.text('欢迎回来，继续照顾你的毛孩子'), findsOneWidget);
    expect(find.byIcon(Icons.pets_rounded), findsOneWidget);

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.title, 'PawCare');
    expect(materialApp.debugShowCheckedModeBanner, isFalse);
    expect(materialApp.theme?.colorScheme.primary, AppColors.warmOrange);
    expect(materialApp.theme?.colorScheme.secondary, AppColors.mintGreen);
  });
}
