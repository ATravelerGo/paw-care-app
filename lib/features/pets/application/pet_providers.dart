import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../core/storage/current_pet_storage.dart';
import '../data/data_sources/pet_remote_data_source.dart';
import '../data/repositories/pet_repository_impl.dart';
import '../domain/repositories/pet_repository.dart';
import 'pet_controller.dart';

final currentPetStorageProvider = Provider<CurrentPetStorage>(
  (ref) => SharedPreferencesCurrentPetStorage(),
  name: 'currentPetStorageProvider',
);

final petRemoteDataSourceProvider = Provider<PetRemoteDataSource>(
  (ref) => ApiPetRemoteDataSource(ref.watch(apiClientProvider)),
  name: 'petRemoteDataSourceProvider',
);

final petRepositoryProvider = Provider<PetRepository>(
  (ref) => PetRepositoryImpl(ref.watch(petRemoteDataSourceProvider)),
  name: 'petRepositoryProvider',
);

final petControllerProvider = Provider<PetController>((ref) {
  final controller = PetController(
    repository: ref.watch(petRepositoryProvider),
    currentPetStorage: ref.watch(currentPetStorageProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
}, name: 'petControllerProvider');
