import '../../../../core/error/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/health_record.dart';

abstract interface class HealthRemoteDataSource {
  Future<List<HealthRecord>> getRecords(String petId);
  Future<HealthRecord> createRecord(String petId, HealthRecordDraft draft);
  Future<HealthRecord> updateRecord(
    String petId,
    String recordId,
    HealthRecordDraft draft,
  );
  Future<void> deleteRecord(String petId, String recordId);
}

final class ApiHealthRemoteDataSource implements HealthRemoteDataSource {
  ApiHealthRemoteDataSource(this._apiClient);
  final ApiClient _apiClient;

  String _path(String petId, [String? recordId]) =>
      'pets/$petId/health-records${recordId == null ? '' : '/$recordId'}';

  @override
  Future<List<HealthRecord>> getRecords(String petId) async {
    final response = await _apiClient.get<List<dynamic>>(_path(petId));
    final body = response.data;
    if (body == null) throw const UnexpectedException('健康记录响应为空');
    try {
      return body.map((item) => _fromJson(item, petId)).toList(growable: false);
    } on FormatException catch (error) {
      throw UnexpectedException('健康记录格式错误', cause: error);
    }
  }

  @override
  Future<HealthRecord> createRecord(
    String petId,
    HealthRecordDraft draft,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      _path(petId),
      data: _toJson(draft),
    );
    return _fromJson(response.data, petId);
  }

  @override
  Future<HealthRecord> updateRecord(
    String petId,
    String recordId,
    HealthRecordDraft draft,
  ) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      _path(petId, recordId),
      data: _toJson(draft),
    );
    return _fromJson(response.data, petId);
  }

  @override
  Future<void> deleteRecord(String petId, String recordId) async {
    await _apiClient.delete<void>(_path(petId, recordId));
  }

  Map<String, dynamic> _toJson(HealthRecordDraft draft) => {
    'recordType': draft.recordType,
    if (draft.title.trim().isNotEmpty) 'title': draft.title.trim(),
    'description': draft.description.trim(),
    'recordDate': draft.recordDate.toUtc().toIso8601String(),
  };

  HealthRecord _fromJson(dynamic value, String petId) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Expected a health record object.');
    }
    final recordDate = DateTime.tryParse(value['recordDate'] as String? ?? '');
    final metadataValue = value['metadata'];
    if (recordDate == null ||
        value['id'] is! String ||
        value['recordType'] is! String ||
        value['description'] is! String ||
        (metadataValue != null && metadataValue is! Map<String, dynamic>)) {
      throw const FormatException('Invalid health record fields.');
    }
    return HealthRecord(
      id: value['id'] as String,
      petId: value['petId'] as String? ?? petId,
      recordType: value['recordType'] as String,
      title: value['title'] as String?,
      description: value['description'] as String,
      recordDate: recordDate.toLocal(),
      metadata: metadataValue as Map<String, dynamic>? ?? const {},
    );
  }
}
