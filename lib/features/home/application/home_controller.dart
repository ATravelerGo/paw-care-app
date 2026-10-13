import 'package:flutter/foundation.dart';

import '../domain/models/health_record_summary.dart';
import '../domain/repositories/home_repository.dart';

enum HomeSummaryStatus { idle, loading, ready, failure }

final class HomeController extends ChangeNotifier {
  HomeController({required this.repository});

  final HomeRepository repository;

  HomeSummaryStatus _status = HomeSummaryStatus.idle;
  List<HealthRecordSummary> _recentRecords = const [];
  String? _petId;
  Object? _error;
  bool _isDisposed = false;

  HomeSummaryStatus get status => _status;
  List<HealthRecordSummary> get recentRecords =>
      List.unmodifiable(_recentRecords);
  Object? get error => _error;

  Future<void> loadForPet(String petId, {bool force = false}) async {
    if (!force && _petId == petId && _status != HomeSummaryStatus.failure) {
      return;
    }
    _petId = petId;
    _status = HomeSummaryStatus.loading;
    _error = null;
    _notify();
    try {
      _recentRecords = await repository.getRecentHealthRecords(petId);
      _status = HomeSummaryStatus.ready;
    } on Object catch (error) {
      _status = HomeSummaryStatus.failure;
      _error = error;
    }
    _notify();
  }

  void clear() {
    if (_status == HomeSummaryStatus.idle && _recentRecords.isEmpty) return;
    _petId = null;
    _status = HomeSummaryStatus.idle;
    _recentRecords = const [];
    _error = null;
    _notify();
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
