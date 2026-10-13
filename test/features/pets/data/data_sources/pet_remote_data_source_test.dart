import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care_app/core/auth/auth_session_invalidator.dart';
import 'package:paw_care_app/core/config/app_config.dart';
import 'package:paw_care_app/core/network/api_client.dart';
import 'package:paw_care_app/features/pets/data/data_sources/pet_remote_data_source.dart';
import 'package:paw_care_app/features/pets/domain/models/pet.dart';

import '../../../../helpers/in_memory_token_storage.dart';

void main() {
  late Dio dio;
  late ApiPetRemoteDataSource dataSource;
  late RequestOptions capturedRequest;

  setUp(() {
    dio = Dio();
    dataSource = ApiPetRemoteDataSource(
      ApiClient(
        config: AppConfig.fromValues(
          environmentName: 'dev',
          apiBaseUrl: 'https://api.pawcare.example/api',
        ),
        tokenStorage: InMemoryTokenStorage('stored-token'),
        sessionInvalidator: AuthSessionInvalidator(),
        dio: dio,
      ),
    );
  });

  test('loads the current user pets with the stored token', () async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          handler.resolve(
            Response<List<dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: [
                {
                  'id': 'pet-id',
                  'name': '团子',
                  'species': 'cat',
                  'breed': '英短',
                  'gender': 'female',
                },
              ],
            ),
          );
        },
      ),
    );

    final pets = await dataSource.getPets();

    expect(capturedRequest.uri.path, '/api/pets');
    expect(capturedRequest.headers['Authorization'], 'Bearer stored-token');
    expect(pets.single.name, '团子');
    expect(pets.single.speciesLabel, '猫咪');
  });

  test('creates a pet with normalized optional fields', () async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 201,
              data: {
                'id': 'pet-id',
                'name': '团子',
                'species': 'cat',
                'breed': null,
                'gender': null,
              },
            ),
          );
        },
      ),
    );

    final pet = await dataSource.createPet(
      const PetDraft(name: ' 团子 ', species: 'cat', breed: ' ', gender: ' '),
    );

    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.uri.path, '/api/pets');
    expect(capturedRequest.data, {'name': '团子', 'species': 'cat'});
    expect(pet.id, 'pet-id');
  });
}
