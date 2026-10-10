import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_session_invalidator.dart';
import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_token_storage.dart';
import '../core/storage/token_storage.dart';

final appConfigProvider = Provider<AppConfig>(
  (ref) => throw StateError(
    'AppConfig must be overridden in the root ProviderScope.',
  ),
  name: 'appConfigProvider',
);

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(),
  name: 'tokenStorageProvider',
);

final authSessionInvalidatorProvider = Provider<AuthSessionInvalidator>((ref) {
  final invalidator = AuthSessionInvalidator();
  ref.onDispose(invalidator.dispose);
  return invalidator;
}, name: 'authSessionInvalidatorProvider');

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    config: ref.watch(appConfigProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    sessionInvalidator: ref.watch(authSessionInvalidatorProvider),
  ),
  name: 'apiClientProvider',
);
