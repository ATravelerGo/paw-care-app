import '../../../../core/error/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/health_record_summary.dart';

abstract interface class HomeRemoteDataSource {
  Future<List<HealthRecordSummary>> getRecentHealthRecords(String petId);
}

final class ApiHomeRemoteDataSource implements HomeRemoteDataSource {
  ApiHomeRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<HealthRecordSummary>> getRecentHealthRecords(String petId) async {
    final response = await _apiClient.get<List<dynamic>>(
      'pets/$petId/health-records',
    );
    final body = response.data;
    if (body == null) throw const UnexpectedException('健康记录响应为空');
    try {
      return body.map(_fromJson).take(3).toList(growable: false);
    } on FormatException catch (error) {
      throw UnexpectedException('健康记录格式错误', cause: error);
    }
  }

  HealthRecordSummary _fromJson(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Expected a health record object.');
    }
    return HealthRecordSummary(
      id: _requiredString(value, 'id'),
      recordType: _requiredString(value, 'recordType'),
      description: _requiredString(value, 'description'),
      recordDate: _requiredDate(value, 'recordDate'),
      title: _nullableString(value, 'title'),
    );
  }

  String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    throw FormatException('Expected a non-empty string for "$key".');
  }

  String? _nullableString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null || value is String) {
      return value as String?;
    }
    throw FormatException('Expected a string or null for "$key".');
  }

  DateTime _requiredDate(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('Expected a date for "$key".');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('Expected an ISO date for "$key".');
    }
    return parsed.toLocal();
  }
}
