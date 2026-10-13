import 'package:paw_care_app/core/storage/current_pet_storage.dart';

final class InMemoryCurrentPetStorage implements CurrentPetStorage {
  InMemoryCurrentPetStorage([this.currentPetId]);

  String? currentPetId;

  @override
  Future<void> clearCurrentPetId() async {
    currentPetId = null;
  }

  @override
  Future<String?> readCurrentPetId() async => currentPetId;

  @override
  Future<void> saveCurrentPetId(String petId) async {
    currentPetId = petId;
  }
}
