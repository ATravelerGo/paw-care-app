import '../../domain/models/health_record_summary.dart';
import '../../domain/repositories/home_repository.dart';
import '../data_sources/home_remote_data_source.dart';

final class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._remoteDataSource);

  final HomeRemoteDataSource _remoteDataSource;

  @override
  Future<List<HealthRecordSummary>> getRecentHealthRecords(String petId) =>
      _remoteDataSource.getRecentHealthRecords(petId);
}
