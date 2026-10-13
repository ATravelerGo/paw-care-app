import '../../domain/models/pet.dart';
import '../../domain/repositories/pet_repository.dart';
import '../data_sources/pet_remote_data_source.dart';

final class PetRepositoryImpl implements PetRepository {
  PetRepositoryImpl(this._remoteDataSource);

  final PetRemoteDataSource _remoteDataSource;

  @override
  Future<Pet> createPet(PetDraft draft) => _remoteDataSource.createPet(draft);

  @override
  Future<void> deletePet(String petId) => _remoteDataSource.deletePet(petId);

  @override
  Future<List<Pet>> getPets() => _remoteDataSource.getPets();

  @override
  Future<Pet> updatePet(String petId, PetDraft draft) =>
      _remoteDataSource.updatePet(petId, draft);
}
