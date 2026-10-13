import '../../../../core/error/app_exception.dart';
import '../../domain/models/pet.dart';

abstract final class PetJson {
  static Pet fromJson(Map<String, dynamic> json) {
    try {
      return Pet(
        id: _requiredString(json, 'id'),
        name: _requiredString(json, 'name'),
        species: _requiredString(json, 'species'),
        breed: _nullableString(json, 'breed'),
        gender: _nullableString(json, 'gender'),
      );
    } on FormatException catch (error) {
      throw UnexpectedException('宠物信息格式错误', cause: error);
    }
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw FormatException('Expected a non-empty string for "$key".');
  }

  static String? _nullableString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null || value is String) return value as String?;
    throw FormatException('Expected a string or null for "$key".');
  }
}
