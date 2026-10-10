enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment parse(String value) {
    return switch (value.trim().toLowerCase()) {
      'dev' || 'development' => AppEnvironment.development,
      'staging' => AppEnvironment.staging,
      'prod' || 'production' => AppEnvironment.production,
      _ => throw ArgumentError.value(
        value,
        'APP_ENV',
        'Expected dev, staging, or prod.',
      ),
    };
  }
}

class AppConfig {
  const AppConfig({required this.environment, required this.apiBaseUri});

  factory AppConfig.fromEnvironment() {
    const environmentName = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'dev',
    );
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

    return AppConfig.fromValues(
      environmentName: environmentName,
      apiBaseUrl: apiBaseUrl,
    );
  }

  factory AppConfig.fromValues({
    required String environmentName,
    required String apiBaseUrl,
  }) {
    final environment = AppEnvironment.parse(environmentName);
    final resolvedApiBaseUrl = apiBaseUrl.trim().isEmpty
        ? _defaultApiBaseUrl(environment)
        : apiBaseUrl.trim();
    final apiBaseUri = Uri.tryParse(resolvedApiBaseUrl);

    if (apiBaseUri == null ||
        !apiBaseUri.hasScheme ||
        !apiBaseUri.hasAuthority ||
        (apiBaseUri.scheme != 'http' && apiBaseUri.scheme != 'https')) {
      throw ArgumentError.value(
        resolvedApiBaseUrl,
        'API_BASE_URL',
        'Expected an absolute http or https URL.',
      );
    }

    final normalizedApiBaseUri = apiBaseUri.replace(
      path: apiBaseUri.path.endsWith('/')
          ? apiBaseUri.path
          : '${apiBaseUri.path}/',
    );

    return AppConfig(
      environment: environment,
      apiBaseUri: normalizedApiBaseUri,
    );
  }

  final AppEnvironment environment;
  final Uri apiBaseUri;

  String get appName => switch (environment) {
    AppEnvironment.development => 'PawCare Dev',
    AppEnvironment.staging => 'PawCare Staging',
    AppEnvironment.production => 'PawCare',
  };

  static String _defaultApiBaseUrl(AppEnvironment environment) {
    if (environment == AppEnvironment.development) {
      return 'http://127.0.0.1:3000/api';
    }

    throw StateError('API_BASE_URL must be provided for ${environment.name}.');
  }
}
