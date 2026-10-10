import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care_app/app/app_providers.dart';
import 'package:paw_care_app/core/config/app_config.dart';
import 'package:paw_care_app/core/network/api_client.dart';

import '../helpers/in_memory_token_storage.dart';

void main() {
  test('provides shared application dependencies', () {
    final config = AppConfig.fromValues(
      environmentName: 'dev',
      apiBaseUrl: 'https://api.pawcare.example',
    );
    final tokenStorage = InMemoryTokenStorage();
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        tokenStorageProvider.overrideWithValue(tokenStorage),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(appConfigProvider), same(config));
    expect(container.read(tokenStorageProvider), same(tokenStorage));

    final apiClient = container.read(apiClientProvider);
    expect(apiClient, isA<ApiClient>());
    expect(container.read(apiClientProvider), same(apiClient));
  });
}
