import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care_app/features/health/domain/models/health_record.dart';
import 'package:paw_care_app/features/health/domain/models/weight_trend.dart';

void main() {
  test('extracts weight values from metadata and record descriptions', () {
    final trend = WeightTrendData.fromRecords(
      [
        _record(
          id: 'metadata-number',
          date: DateTime(2026, 10, 1),
          metadata: const {'weight': 5.1},
        ),
        _record(
          id: 'metadata-grams',
          date: DateTime(2026, 10, 2),
          metadata: const {'weightKg': '5200 g'},
        ),
        _record(
          id: 'description',
          date: DateTime(2026, 10, 3),
          description: '今天体重 5.3 kg',
        ),
      ],
      range: WeightTrendRange.all,
      now: DateTime(2026, 10, 13),
    );

    expect(trend.points.map((point) => point.kilograms), [5.1, 5.2, 5.3]);
    expect(trend.unreadableRecordCount, 0);
  });

  test('filters by range and reports unreadable records', () {
    final trend = WeightTrendData.fromRecords(
      [
        _record(
          id: 'outside',
          date: DateTime(2026, 8, 1),
          description: '4.8 kg',
        ),
        _record(
          id: 'inside',
          date: DateTime(2026, 10, 1),
          description: '5.0 kg',
        ),
        _record(
          id: 'invalid',
          date: DateTime(2026, 10, 2),
          description: '今天称重了，但忘记记录数值',
        ),
      ],
      range: WeightTrendRange.days30,
      now: DateTime(2026, 10, 13),
    );

    expect(trend.points.single.recordId, 'inside');
    expect(trend.unreadableRecordCount, 1);
  });

  test('marks a change of twenty percent or more as anomalous', () {
    final trend = WeightTrendData.fromRecords(
      [
        _record(
          id: 'first',
          date: DateTime(2026, 10, 1),
          description: '5.0 kg',
        ),
        _record(
          id: 'second',
          date: DateTime(2026, 10, 2),
          description: '6.0 kg',
        ),
      ],
      range: WeightTrendRange.all,
      now: DateTime(2026, 10, 13),
    );

    expect(trend.points.first.isAnomalous, isFalse);
    expect(trend.points.last.isAnomalous, isTrue);
    expect(trend.hasAnomaly, isTrue);
    expect(trend.change, 1.0);
  });
}

HealthRecord _record({
  required String id,
  required DateTime date,
  String description = '体重记录',
  Map<String, dynamic> metadata = const {},
}) {
  return HealthRecord(
    id: id,
    petId: 'pet-1',
    recordType: 'weight',
    description: description,
    recordDate: date,
    metadata: metadata,
  );
}
