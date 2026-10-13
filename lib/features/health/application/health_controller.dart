import 'package:flutter/material.dart';

import '../domain/models/health_record.dart';
import '../domain/repositories/health_repository.dart';

enum HealthRecordsStatus { initial, loading, ready, failure }

final class HealthController extends ChangeNotifier {
  HealthController({required this.repository});
  final HealthRepository repository;
  HealthRecordsStatus _status = HealthRecordsStatus.initial;
  List<HealthRecord> _records = const [];
  String? _petId;
  String? _recordTypeFilter;
  DateTimeRange? _dateRange;
  bool _isSaving = false;
  bool _disposed = false;

  HealthRecordsStatus get status => _status;
  List<HealthRecord> get records => List.unmodifiable(_records);
  List<HealthRecord> get visibleRecords => _records
      .where((record) {
        if (_recordTypeFilter != null &&
            record.recordType != _recordTypeFilter) {
          return false;
        }
        final range = _dateRange;
        if (range == null) return true;
        final date = DateTime(
          record.recordDate.year,
          record.recordDate.month,
          record.recordDate.day,
        );
        return !date.isBefore(range.start) && !date.isAfter(range.end);
      })
      .toList(growable: false);
  String? get currentPetId => _petId;
  String? get recordTypeFilter => _recordTypeFilter;
  DateTimeRange? get dateRange => _dateRange;
  bool get isSaving => _isSaving;

  Future<void> load(String petId, {bool force = false}) async {
    if (_status == HealthRecordsStatus.loading ||
        (!force && _status == HealthRecordsStatus.ready && _petId == petId)) {
      return;
    }
    _petId = petId;
    _status = HealthRecordsStatus.loading;
    _notify();
    try {
      _records = await repository.getRecords(petId);
      _status = HealthRecordsStatus.ready;
    } on Object {
      _status = HealthRecordsStatus.failure;
    }
    _notify();
  }

  HealthRecord? recordById(String id) {
    for (final record in _records) {
      if (record.id == id) return record;
    }
    return null;
  }

  void setRecordTypeFilter(String? value) {
    _recordTypeFilter = value;
    _notify();
  }

  void setDateRange(DateTimeRange? value) {
    _dateRange = value;
    _notify();
  }

  Future<void> save(HealthRecordDraft draft, {String? recordId}) async {
    final petId = _petId;
    if (petId == null) throw StateError('No current pet is selected.');
    await _saving(() async {
      if (recordId == null) {
        final created = await repository.createRecord(petId, draft);
        _records = [created, ..._records];
      } else {
        final updated = await repository.updateRecord(petId, recordId, draft);
        _records = [
          for (final item in _records) item.id == recordId ? updated : item,
        ];
        _records.sort((a, b) => b.recordDate.compareTo(a.recordDate));
      }
      _status = HealthRecordsStatus.ready;
    });
  }

  Future<void> delete(String recordId) async {
    final petId = _petId;
    if (petId == null) throw StateError('No current pet is selected.');
    await _saving(() async {
      await repository.deleteRecord(petId, recordId);
      _records = _records
          .where((item) => item.id != recordId)
          .toList(growable: false);
    });
  }

  Future<void> _saving(Future<void> Function() action) async {
    if (_isSaving) throw StateError('A health record change is in progress.');
    _isSaving = true;
    _notify();
    try {
      await action();
    } finally {
      _isSaving = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
