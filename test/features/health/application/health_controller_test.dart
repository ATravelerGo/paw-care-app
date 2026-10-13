import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care_app/features/health/application/health_controller.dart';
import 'package:paw_care_app/features/health/domain/models/health_record.dart';

import '../../../helpers/fake_health_repository.dart';

void main() {
  final records = [
    HealthRecord(
      id: 'symptom',
      petId: 'pet-1',
      recordType: 'symptom',
      title: '咳嗽',
      description: '轻微咳嗽',
      recordDate: DateTime(2026, 10, 10),
    ),
    HealthRecord(
      id: 'vaccine',
      petId: 'pet-1',
      recordType: 'vaccine',
      title: '疫苗',
      description: '完成接种',
      recordDate: DateTime(2026, 9, 1),
    ),
  ];

  test('loads records only for the selected pet', () async {
    final repository = FakeHealthRepository(
      records: [
        ...records,
        HealthRecord(
          id: 'other',
          petId: 'pet-2',
          recordType: 'diet',
          description: '正常',
          recordDate: DateTime(2026, 10, 11),
        ),
      ],
    );
    final controller = HealthController(repository: repository);

    await controller.load('pet-1');

    expect(controller.records.map((item) => item.id), ['symptom', 'vaccine']);
    expect(controller.status, HealthRecordsStatus.ready);
  });

  test('filters records by type and inclusive date range', () async {
    final controller = HealthController(
      repository: FakeHealthRepository(records: records),
    );
    await controller.load('pet-1');

    controller.setRecordTypeFilter('symptom');
    expect(controller.visibleRecords.single.id, 'symptom');

    controller.setRecordTypeFilter(null);
    controller.setDateRange(
      DateTimeRange(start: DateTime(2026, 10, 10), end: DateTime(2026, 10, 10)),
    );
    expect(controller.visibleRecords.single.id, 'symptom');
  });

  test('creates, updates, and deletes a health record', () async {
    final controller = HealthController(repository: FakeHealthRepository());
    await controller.load('pet-1');
    final draft = HealthRecordDraft(
      recordType: 'weight',
      title: '体重',
      description: '5.2kg',
      recordDate: DateTime(2026, 10, 13),
    );

    await controller.save(draft);
    expect(controller.records.single.id, 'created-record');

    await controller.save(
      HealthRecordDraft(
        recordType: 'weight',
        title: '体重更新',
        description: '5.3kg',
        recordDate: DateTime(2026, 10, 14),
      ),
      recordId: 'created-record',
    );
    expect(controller.records.single.description, '5.3kg');

    await controller.delete('created-record');
    expect(controller.records, isEmpty);
  });
}
