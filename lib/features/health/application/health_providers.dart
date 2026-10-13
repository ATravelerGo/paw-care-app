import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../data/data_sources/health_remote_data_source.dart';
import '../data/repositories/health_repository_impl.dart';
import '../domain/repositories/health_repository.dart';
import 'health_controller.dart';

final healthRemoteDataSourceProvider = Provider<HealthRemoteDataSource>(
  (ref) => ApiHealthRemoteDataSource(ref.watch(apiClientProvider)),
);

final healthRepositoryProvider = Provider<HealthRepository>(
  (ref) => HealthRepositoryImpl(ref.watch(healthRemoteDataSourceProvider)),
);

final healthControllerProvider = Provider<HealthController>((ref) {
  final controller = HealthController(
    repository: ref.watch(healthRepositoryProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});
