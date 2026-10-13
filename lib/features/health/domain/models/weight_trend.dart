import 'health_record.dart';

enum WeightTrendRange {
  days30('30天', 30),
  days90('90天', 90),
  year('1年', 365),
  all('全部', null);

  const WeightTrendRange(this.label, this.days);

  final String label;
  final int? days;
}

final class WeightMeasurement {
  const WeightMeasurement({
    required this.recordId,
    required this.date,
    required this.kilograms,
    this.isAnomalous = false,
  });

  final String recordId;
  final DateTime date;
  final double kilograms;
  final bool isAnomalous;

  WeightMeasurement markAnomalous() => WeightMeasurement(
    recordId: recordId,
    date: date,
    kilograms: kilograms,
    isAnomalous: true,
  );
}

final class WeightTrendData {
  const WeightTrendData({
    required this.points,
    required this.unreadableRecordCount,
  });

  factory WeightTrendData.fromRecords(
    List<HealthRecord> records, {
    required WeightTrendRange range,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final cutoff = range.days == null
        ? null
        : DateTime(
            today.year,
            today.month,
            today.day,
          ).subtract(Duration(days: range.days! - 1));
    final weightRecords = records.where(
      (record) =>
          record.recordType == 'weight' &&
          (cutoff == null || !record.recordDate.isBefore(cutoff)),
    );
    var unreadableRecordCount = 0;
    final parsed = <WeightMeasurement>[];

    for (final record in weightRecords) {
      final kilograms = _weightInKilograms(record);
      if (kilograms == null) {
        unreadableRecordCount++;
        continue;
      }
      parsed.add(
        WeightMeasurement(
          recordId: record.id,
          date: record.recordDate,
          kilograms: kilograms,
        ),
      );
    }
    parsed.sort((a, b) => a.date.compareTo(b.date));

    final points = <WeightMeasurement>[];
    for (final point in parsed) {
      final previous = points.isEmpty ? null : points.last;
      final changeRatio = previous == null
          ? 0.0
          : (point.kilograms - previous.kilograms).abs() / previous.kilograms;
      points.add(changeRatio >= 0.2 ? point.markAnomalous() : point);
    }

    return WeightTrendData(
      points: List.unmodifiable(points),
      unreadableRecordCount: unreadableRecordCount,
    );
  }

  final List<WeightMeasurement> points;
  final int unreadableRecordCount;

  WeightMeasurement? get latest => points.isEmpty ? null : points.last;
  bool get hasAnomaly => points.any((point) => point.isAnomalous);
  double? get change {
    if (points.length < 2) return null;
    return points.last.kilograms - points.first.kilograms;
  }
}

double? _weightInKilograms(HealthRecord record) {
  for (final key in const ['weightKg', 'weight_kg', 'weight']) {
    final value = _parseWeight(record.metadata[key]);
    if (value != null) return value;
  }

  final combinedText = '${record.title ?? ''} ${record.description}';
  return parseWeightKilograms(combinedText) ??
      parseWeightKilograms(record.description);
}

double? parseWeightKilograms(String text) {
  final withUnit = RegExp(
    r'(\d+(?:\.\d+)?)\s*(kg|公斤|千克|g|克)',
    caseSensitive: false,
  ).firstMatch(text);
  if (withUnit != null) {
    return _normalizeWeight(
      double.tryParse(withUnit.group(1)!),
      withUnit.group(2),
    );
  }

  final bareNumber = RegExp(
    r'^\s*(?:体重[:：]?\s*)?(\d+(?:\.\d+)?)\s*$',
    caseSensitive: false,
  ).firstMatch(text);
  return bareNumber == null
      ? null
      : _normalizeWeight(double.tryParse(bareNumber.group(1)!), null);
}

double? _parseWeight(dynamic value) {
  if (value is num) return _normalizeWeight(value.toDouble(), null);
  if (value is! String) return null;
  final match = RegExp(
    r'^\s*(\d+(?:\.\d+)?)\s*(kg|公斤|千克|g|克)?\s*$',
    caseSensitive: false,
  ).firstMatch(value);
  if (match == null) return null;
  return _normalizeWeight(double.tryParse(match.group(1)!), match.group(2));
}

double? _normalizeWeight(double? value, String? unit) {
  if (value == null) return null;
  final normalizedUnit = unit?.toLowerCase();
  final kilograms = normalizedUnit == 'g' || normalizedUnit == '克'
      ? value / 1000
      : value;
  if (kilograms <= 0 || kilograms > 200) return null;
  return kilograms;
}
