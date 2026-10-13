import 'package:paw_care_app/features/pets/domain/models/pet.dart';
import 'package:paw_care_app/features/pets/domain/repositories/pet_repository.dart';

final class FakePetRepository implements PetRepository {
  FakePetRepository({List<Pet> pets = const []}) : pets = [...pets];

  final List<Pet> pets;
  Object? getPetsError;
  Object? mutationError;
  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;

  @override
  Future<Pet> createPet(PetDraft draft) async {
    createCalls++;
    final error = mutationError;
    if (error != null) throw error;
    final pet = Pet(
      id: 'pet-${pets.length + 1}',
      name: draft.name.trim(),
      species: draft.species.trim(),
      breed: _normalizedOrNull(draft.breed),
      gender: _normalizedOrNull(draft.gender),
    );
    pets.add(pet);
    return pet;
  }

  @override
  Future<void> deletePet(String petId) async {
    deleteCalls++;
    final error = mutationError;
    if (error != null) throw error;
    pets.removeWhere((pet) => pet.id == petId);
  }

  @override
  Future<List<Pet>> getPets() async {
    final error = getPetsError;
    if (error != null) throw error;
    return List.unmodifiable(pets);
  }

  @override
  Future<Pet> updatePet(String petId, PetDraft draft) async {
    updateCalls++;
    final error = mutationError;
    if (error != null) throw error;
    final index = pets.indexWhere((pet) => pet.id == petId);
    if (index < 0) throw StateError('Pet not found.');
    final pet = Pet(
      id: petId,
      name: draft.name.trim(),
      species: draft.species.trim(),
      breed: _normalizedOrNull(draft.breed),
      gender: _normalizedOrNull(draft.gender),
    );
    pets[index] = pet;
    return pet;
  }
}

String? _normalizedOrNull(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
