import '../../../../core/error/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/pet.dart';
import '../models/pet_json.dart';

abstract interface class PetRemoteDataSource {
  Future<List<Pet>> getPets();

  Future<Pet> createPet(PetDraft draft);

  Future<Pet> updatePet(String petId, PetDraft draft);

  Future<void> deletePet(String petId);
}

final class ApiPetRemoteDataSource implements PetRemoteDataSource {
  ApiPetRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<Pet> createPet(PetDraft draft) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      'pets',
      data: draft.toJson(),
    );
    return _decodePet(response.data);
  }

  @override
  Future<void> deletePet(String petId) async {
    await _apiClient.delete<void>('pets/$petId');
  }

  @override
  Future<List<Pet>> getPets() async {
    final response = await _apiClient.get<List<dynamic>>('pets');
    final body = response.data;
    if (body == null) throw const UnexpectedException('宠物列表响应为空');
    try {
      return body
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Expected a pet object.');
            }
            return PetJson.fromJson(item);
          })
          .toList(growable: false);
    } on FormatException catch (error) {
      throw UnexpectedException('宠物列表格式错误', cause: error);
    }
  }

  @override
  Future<Pet> updatePet(String petId, PetDraft draft) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      'pets/$petId',
      data: draft.toJson(),
    );
    return _decodePet(response.data);
  }

  Pet _decodePet(Map<String, dynamic>? body) {
    if (body == null) throw const UnexpectedException('宠物响应为空');
    return PetJson.fromJson(body);
  }
}
