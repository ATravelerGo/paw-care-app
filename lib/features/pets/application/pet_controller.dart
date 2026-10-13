import 'package:flutter/foundation.dart';

import '../../../core/storage/current_pet_storage.dart';
import '../domain/models/pet.dart';
import '../domain/repositories/pet_repository.dart';

enum PetListStatus { initial, loading, ready, failure }

final class PetController extends ChangeNotifier {
  PetController({required this.repository, required this.currentPetStorage});

  final PetRepository repository;
  final CurrentPetStorage currentPetStorage;

  PetListStatus _status = PetListStatus.initial;
  List<Pet> _pets = const [];
  String? _currentPetId;
  Object? _error;
  bool _isSaving = false;
  bool _isDisposed = false;

  PetListStatus get status => _status;
  List<Pet> get pets => List.unmodifiable(_pets);
  Object? get error => _error;
  bool get isSaving => _isSaving;
  Pet? get currentPet => _findById(_currentPetId);

  Pet? petById(String petId) => _findById(petId);

  Future<void> load({bool force = false}) async {
    if (_status == PetListStatus.loading ||
        (!force && _status == PetListStatus.ready)) {
      return;
    }

    _status = PetListStatus.loading;
    _error = null;
    _notify();

    try {
      final results = await Future.wait<dynamic>([
        repository.getPets(),
        currentPetStorage.readCurrentPetId(),
      ]);
      final loadedPets = results[0] as List<Pet>;
      final savedPetId = results[1] as String?;

      _pets = loadedPets;
      _currentPetId = _selectExistingOrFirst(savedPetId);
      await _persistCurrentPetId();
      _status = PetListStatus.ready;
    } on Object catch (error) {
      _status = PetListStatus.failure;
      _error = error;
    }
    _notify();
  }

  Future<void> selectPet(String petId) async {
    if (_findById(petId) == null) {
      throw ArgumentError.value(petId, 'petId', 'Pet must exist in the list.');
    }
    _currentPetId = petId;
    await _persistCurrentPetId();
    _notify();
  }

  Future<Pet> createPet(PetDraft draft) async {
    return _runSaving(() async {
      final pet = await repository.createPet(draft);
      _pets = [..._pets, pet];
      _currentPetId = pet.id;
      await _persistCurrentPetId();
      _status = PetListStatus.ready;
      return pet;
    });
  }

  Future<Pet> updatePet(String petId, PetDraft draft) async {
    return _runSaving(() async {
      final pet = await repository.updatePet(petId, draft);
      _pets = [
        for (final item in _pets)
          if (item.id == petId) pet else item,
      ];
      _status = PetListStatus.ready;
      return pet;
    });
  }

  Future<void> deletePet(String petId) async {
    await _runSaving(() async {
      await repository.deletePet(petId);
      _pets = _pets.where((pet) => pet.id != petId).toList(growable: false);
      if (_currentPetId == petId) {
        _currentPetId = _pets.isEmpty ? null : _pets.first.id;
        await _persistCurrentPetId();
      }
      _status = PetListStatus.ready;
    });
  }

  Future<T> _runSaving<T>(Future<T> Function() action) async {
    if (_isSaving) {
      throw StateError('Another pet change is already in progress.');
    }
    _isSaving = true;
    _error = null;
    _notify();
    try {
      return await action();
    } on Object catch (error) {
      _error = error;
      rethrow;
    } finally {
      _isSaving = false;
      _notify();
    }
  }

  String? _selectExistingOrFirst(String? savedPetId) {
    if (_pets.isEmpty) {
      return null;
    }
    return _findById(savedPetId) != null ? savedPetId : _pets.first.id;
  }

  Pet? _findById(String? petId) {
    if (petId == null) {
      return null;
    }
    for (final pet in _pets) {
      if (pet.id == petId) {
        return pet;
      }
    }
    return null;
  }

  Future<void> _persistCurrentPetId() {
    final currentPetId = _currentPetId;
    return currentPetId == null
        ? currentPetStorage.clearCurrentPetId()
        : currentPetStorage.saveCurrentPetId(currentPetId);
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
