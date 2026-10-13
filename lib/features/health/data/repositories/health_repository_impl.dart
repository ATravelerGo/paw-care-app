import '../../domain/models/health_record.dart';
import '../../domain/repositories/health_repository.dart';
import '../data_sources/health_remote_data_source.dart';

final class HealthRepositoryImpl implements HealthRepository {
  HealthRepositoryImpl(this._remote);
  final HealthRemoteDataSource _remote;

  @override
  Future<List<HealthRecord>> getRecords(String petId) =>
      _remote.getRecords(petId);

  @override
  Future<HealthRecord> createRecord(String petId, HealthRecordDraft draft) =>
      _remote.createRecord(petId, draft);

  @override
  Future<HealthRecord> updateRecord(
    String petId,
    String recordId,
    HealthRecordDraft draft,
  ) => _remote.updateRecord(petId, recordId, draft);

  @override
  Future<void> deleteRecord(String petId, String recordId) =>
      _remote.deleteRecord(petId, recordId);
}
