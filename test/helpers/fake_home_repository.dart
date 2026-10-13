import 'package:paw_care_app/features/home/domain/models/health_record_summary.dart';
import 'package:paw_care_app/features/home/domain/repositories/home_repository.dart';

final class FakeHomeRepository implements HomeRepository {
  FakeHomeRepository({this.records = const []});

  List<HealthRecordSummary> records;
  Object? error;
  int calls = 0;
  String? lastPetId;

  @override
  Future<List<HealthRecordSummary>> getRecentHealthRecords(String petId) async {
    calls++;
    lastPetId = petId;
    final currentError = error;
    if (currentError != null) throw currentError;
    return List.unmodifiable(records);
  }
}
