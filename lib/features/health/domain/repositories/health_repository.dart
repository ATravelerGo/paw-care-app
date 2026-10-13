import '../models/health_record.dart';

abstract interface class HealthRepository {
  Future<List<HealthRecord>> getRecords(String petId);
  Future<HealthRecord> createRecord(String petId, HealthRecordDraft draft);
  Future<HealthRecord> updateRecord(
    String petId,
    String recordId,
    HealthRecordDraft draft,
  );
  Future<void> deleteRecord(String petId, String recordId);
}
