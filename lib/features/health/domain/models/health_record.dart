final class HealthRecord {
  const HealthRecord({
    required this.id,
    required this.petId,
    required this.recordType,
    required this.description,
    required this.recordDate,
    this.title,
    this.metadata = const {},
  });

  final String id;
  final String petId;
  final String recordType;
  final String? title;
  final String description;
  final DateTime recordDate;
  final Map<String, dynamic> metadata;

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

final class HealthRecordDraft {
  const HealthRecordDraft({
    required this.recordType,
    required this.title,
    required this.description,
    required this.recordDate,
  });

  final String recordType;
  final String title;
  final String description;
  final DateTime recordDate;
}
