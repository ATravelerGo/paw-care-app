import '../models/health_record_summary.dart';

abstract interface class HomeRepository {
  Future<List<HealthRecordSummary>> getRecentHealthRecords(String petId);
}
