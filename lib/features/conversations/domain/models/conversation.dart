final class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.petId,
    required this.createdAt,
    required this.updatedAt,
    this.title,
  });

  final String id;
  final String petId;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayTitle {
    final value = title?.trim();
    return value == null || value.isEmpty ? '新的健康咨询' : value;
  }
}

final class ConversationMessage {
  const ConversationMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.warnings = const [],
    this.degraded = false,
  });

  final String id;
  final String role;
  final String content;
  final DateTime createdAt;
  final List<AiWarning> warnings;
  final bool degraded;

  bool get isUser => role == 'user';
}

final class ConversationDetail {
  const ConversationDetail({
    required this.id,
    required this.petId,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    this.title,
  });

  final String id;
  final String petId;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ConversationMessage> messages;
}

final class AiWarning {
  const AiWarning({required this.code, required this.message, this.degraded});

  final String code;
  final String message;
  final bool? degraded;
}

final class AiChatResult {
  const AiChatResult({
    required this.answer,
    required this.warnings,
    required this.degraded,
  });

  final String answer;
  final List<AiWarning> warnings;
  final bool degraded;
}
