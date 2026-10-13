import 'package:shared_preferences/shared_preferences.dart';

abstract interface class CurrentPetStorage {
  Future<String?> readCurrentPetId();

  Future<void> saveCurrentPetId(String petId);

  Future<void> clearCurrentPetId();
}

final class SharedPreferencesCurrentPetStorage implements CurrentPetStorage {
  static const _currentPetIdKey = 'pawcare.current_pet_id';

  Future<SharedPreferences> get _preferences => SharedPreferences.getInstance();

  @override
  Future<void> clearCurrentPetId() async {
    await (await _preferences).remove(_currentPetIdKey);
  }

  @override
  Future<String?> readCurrentPetId() async {
    return (await _preferences).getString(_currentPetIdKey);
  }

  @override
  Future<void> saveCurrentPetId(String petId) async {
    final normalizedPetId = petId.trim();
    if (normalizedPetId.isEmpty) {
      throw ArgumentError.value(petId, 'petId', 'Pet ID must not be empty.');
    }
    await (await _preferences).setString(_currentPetIdKey, normalizedPetId);
  }
}
