import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care_app/features/pets/application/pet_controller.dart';
import 'package:paw_care_app/features/pets/domain/models/pet.dart';

import '../../../helpers/fake_pet_repository.dart';
import '../../../helpers/in_memory_current_pet_storage.dart';

void main() {
  const petA = Pet(id: 'pet-a', name: '团子', species: 'cat');
  const petB = Pet(id: 'pet-b', name: '大福', species: 'dog');

  test(
    'restores the saved current pet when it still belongs to the list',
    () async {
      final storage = InMemoryCurrentPetStorage('pet-b');
      final controller = PetController(
        repository: FakePetRepository(pets: const [petA, petB]),
        currentPetStorage: storage,
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.status, PetListStatus.ready);
      expect(controller.currentPet, same(petB));
      expect(storage.currentPetId, 'pet-b');
    },
  );

  test(
    'falls back to the first pet when the saved pet no longer exists',
    () async {
      final storage = InMemoryCurrentPetStorage('removed-pet');
      final controller = PetController(
        repository: FakePetRepository(pets: const [petA, petB]),
        currentPetStorage: storage,
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.currentPet, same(petA));
      expect(storage.currentPetId, 'pet-a');
    },
  );

  test('selects and persists a newly created pet', () async {
    final storage = InMemoryCurrentPetStorage();
    final controller = PetController(
      repository: FakePetRepository(pets: const [petA]),
      currentPetStorage: storage,
    );
    addTearDown(controller.dispose);
    await controller.load();

    final pet = await controller.createPet(
      const PetDraft(name: '  奶盖  ', species: 'dog', breed: '柯基'),
    );

    expect(pet.name, '奶盖');
    expect(controller.currentPet, same(pet));
    expect(storage.currentPetId, pet.id);
    expect(controller.pets, hasLength(2));
  });

  test(
    'moves the current selection to the remaining pet after deletion',
    () async {
      final storage = InMemoryCurrentPetStorage('pet-b');
      final controller = PetController(
        repository: FakePetRepository(pets: const [petA, petB]),
        currentPetStorage: storage,
      );
      addTearDown(controller.dispose);
      await controller.load();

      await controller.deletePet('pet-b');

      expect(controller.currentPet, same(petA));
      expect(storage.currentPetId, 'pet-a');
      expect(controller.pets, [petA]);
    },
  );

  test(
    'clears the persisted current pet after the last pet is deleted',
    () async {
      final storage = InMemoryCurrentPetStorage('pet-a');
      final controller = PetController(
        repository: FakePetRepository(pets: const [petA]),
        currentPetStorage: storage,
      );
      addTearDown(controller.dispose);
      await controller.load();

      await controller.deletePet('pet-a');

      expect(controller.currentPet, isNull);
      expect(controller.pets, isEmpty);
      expect(storage.currentPetId, isNull);
    },
  );
}
