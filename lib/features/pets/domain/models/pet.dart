final class Pet {
  const Pet({
    required this.id,
    required this.name,
    required this.species,
    this.breed,
    this.gender,
  });

  final String id;
  final String name;
  final String species;
  final String? breed;
  final String? gender;

  String get speciesLabel => switch (species.trim().toLowerCase()) {
    'dog' => '狗狗',
    'cat' => '猫咪',
    _ => species,
  };
}

final class PetDraft {
  const PetDraft({
    required this.name,
    required this.species,
    this.breed,
    this.gender,
  });

  final String name;
  final String species;
  final String? breed;
  final String? gender;

  Map<String, String> toJson() {
    final normalizedBreed = breed?.trim();
    final normalizedGender = gender?.trim();
    return {
      'name': name.trim(),
      'species': species.trim(),
      if (normalizedBreed != null && normalizedBreed.isNotEmpty)
        'breed': normalizedBreed,
      if (normalizedGender != null && normalizedGender.isNotEmpty)
        'gender': normalizedGender,
    };
  }
}
