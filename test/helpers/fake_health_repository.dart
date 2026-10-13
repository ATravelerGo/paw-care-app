import 'package:paw_care_app/features/health/domain/models/health_record.dart';
import 'package:paw_care_app/features/health/domain/repositories/health_repository.dart';

final class FakeHealthRepository implements HealthRepository {
  FakeHealthRepository({List<HealthRecord> records = const []})
    : records = [...records];

  List<HealthRecord> records;

  @override
  Future<List<HealthRecord>> getRecords(String petId) async =>
      records.where((item) => item.petId == petId).toList(growable: false);

  @override
  Future<HealthRecord> createRecord(
    String petId,
    HealthRecordDraft draft,
  ) async {
    final record = HealthRecord(
      id: 'created-record',
      petId: petId,
      recordType: draft.recordType,
      title: draft.title,
      description: draft.description,
      recordDate: draft.recordDate,
    );
    records.add(record);
    return record;
  }

  @override
  Future<HealthRecord> updateRecord(
    String petId,
    String recordId,
    HealthRecordDraft draft,
  ) async {
    final record = HealthRecord(
      id: recordId,
      petId: petId,
      recordType: draft.recordType,
      title: draft.title,
      description: draft.description,
      recordDate: draft.recordDate,
    );
    records = [for (final item in records) item.id == recordId ? record : item];
    return record;
  }

  @override
  Future<void> deleteRecord(String petId, String recordId) async {
    records.removeWhere((item) => item.id == recordId && item.petId == petId);
  }
}
