import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care_app/core/auth/auth_session_invalidator.dart';
import 'package:paw_care_app/core/config/app_config.dart';
import 'package:paw_care_app/core/network/api_client.dart';
import 'package:paw_care_app/features/home/data/data_sources/home_remote_data_source.dart';

import '../../../../helpers/in_memory_token_storage.dart';

void main() {
  test('loads only the three most recent health records for a pet', () async {
    final dio = Dio();
    late RequestOptions capturedRequest;
    final dataSource = ApiHomeRemoteDataSource(
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
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          handler.resolve(
            Response<List<dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: [
                for (var index = 1; index <= 4; index++)
                  {
                    'id': 'record-$index',
                    'recordType': 'symptom',
                    'description': '记录 $index',
                    'recordDate':
                        '2026-10-0$index'
                        'T08:00:00.000Z',
                    'title': null,
                  },
              ],
            ),
          );
        },
      ),
    );

    final records = await dataSource.getRecentHealthRecords('pet-id');

    expect(capturedRequest.uri.path, '/api/pets/pet-id/health-records');
    expect(capturedRequest.headers['Authorization'], 'Bearer stored-token');
    expect(records.map((record) => record.id), [
      'record-1',
      'record-2',
      'record-3',
    ]);
    expect(records.first.typeLabel, '症状');
  });
}
