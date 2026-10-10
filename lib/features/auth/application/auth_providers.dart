import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../data/data_sources/auth_remote_data_source.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import 'auth_session_controller.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => ApiAuthRemoteDataSource(ref.watch(apiClientProvider)),
  name: 'authRemoteDataSourceProvider',
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(tokenStorageProvider),
  ),
  name: 'authRepositoryProvider',
);

final authSessionProvider = Provider<AuthSessionController>((ref) {
  final controller = AuthSessionController(
    authRepository: ref.watch(authRepositoryProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    sessionInvalidator: ref.watch(authSessionInvalidatorProvider),
  );
  ref.onDispose(controller.dispose);
  unawaited(controller.restore());
  return controller;
}, name: 'authSessionProvider');
