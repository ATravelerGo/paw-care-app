import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care_app/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('uses the local API URL by default in development', () {
      final config = AppConfig.fromValues(
        environmentName: 'dev',
        apiBaseUrl: '',
      );

      expect(config.environment, AppEnvironment.development);
      expect(config.appName, 'PawCare Dev');
      expect(config.apiBaseUri, Uri.parse('http://127.0.0.1:3000/api/'));
    });

    test('requires an explicit API URL outside development', () {
      expect(
        () => AppConfig.fromValues(environmentName: 'staging', apiBaseUrl: ''),
        throwsStateError,
      );
    });

    test('rejects an unsupported environment', () {
      expect(
        () => AppConfig.fromValues(
          environmentName: 'preview',
          apiBaseUrl: 'https://api.pawcare.example',
        ),
        throwsArgumentError,
      );
    });

    test('rejects a non-http API URL', () {
      expect(
        () => AppConfig.fromValues(
          environmentName: 'prod',
          apiBaseUrl: 'api.pawcare.example',
        ),
        throwsArgumentError,
      );
    });
  });
}
