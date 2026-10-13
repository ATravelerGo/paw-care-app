import '../models/pet.dart';

abstract interface class PetRepository {
  Future<List<Pet>> getPets();

  Future<Pet> createPet(PetDraft draft);

  Future<Pet> updatePet(String petId, PetDraft draft);

  Future<void> deletePet(String petId);
}
