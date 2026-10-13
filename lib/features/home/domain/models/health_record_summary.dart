final class HealthRecordSummary {
  const HealthRecordSummary({
    required this.id,
    required this.recordType,
    required this.description,
    required this.recordDate,
    this.title,
  });

  final String id;
  final String recordType;
  final String description;
  final DateTime recordDate;
  final String? title;

  String get typeLabel => switch (recordType) {
    'symptom' => '症状',
    'vaccine' => '疫苗',
    'medicine' => '用药',
    'checkup' => '检查',
    'weight' => '体重',
    'diet' => '饮食',
    _ => recordType,
  };

  String get displayTitle {
    final value = title?.trim();
    return value == null || value.isEmpty ? description : value;
  }
}
