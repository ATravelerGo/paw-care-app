import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../data/data_sources/home_remote_data_source.dart';
import '../data/repositories/home_repository_impl.dart';
import '../domain/repositories/home_repository.dart';
import 'home_controller.dart';

final homeRemoteDataSourceProvider = Provider<HomeRemoteDataSource>(
  (ref) => ApiHomeRemoteDataSource(ref.watch(apiClientProvider)),
  name: 'homeRemoteDataSourceProvider',
);

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepositoryImpl(ref.watch(homeRemoteDataSourceProvider)),
  name: 'homeRepositoryProvider',
);

final homeControllerProvider = Provider<HomeController>((ref) {
  final controller = HomeController(
    repository: ref.watch(homeRepositoryProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
}, name: 'homeControllerProvider');
