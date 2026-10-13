import 'package:dio/dio.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/conversation.dart';

abstract interface class ConversationRemoteDataSource {
  Future<List<ConversationSummary>> getConversations();
  Future<ConversationSummary> createConversation(String petId);
  Future<ConversationDetail> getConversation(String conversationId);
  Future<AiChatResult> sendMessage({
    required String conversationId,
    required String message,
  });
  Future<void> deleteConversation(String conversationId);
}

final class ApiConversationRemoteDataSource
    implements ConversationRemoteDataSource {
  ApiConversationRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ConversationSummary> createConversation(String petId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      'ai/conversation',
      data: {'petId': petId},
    );
    // The creation endpoint returns the list representation, which intentionally
    // has no petId. Read the detail once so the client can retain the pet
    // boundary used by the conversation list.
    final created = _requiredBody(response.data);
    final detail = await getConversation(_requiredString(created, 'id'));
    return ConversationSummary(
      id: detail.id,
      petId: detail.petId,
      title: detail.title,
      createdAt: detail.createdAt,
      updatedAt: detail.updatedAt,
    );
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    await _apiClient.delete<void>('ai/conversation/$conversationId');
  }

  @override
  Future<ConversationDetail> getConversation(String conversationId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      'ai/conversations/$conversationId',
    );
    return _detailFromJson(_requiredBody(response.data));
  }

  @override
  Future<List<ConversationSummary>> getConversations() async {
    final response = await _apiClient.get<List<dynamic>>('ai/conversation');
    final body = response.data;
    if (body == null) throw const UnexpectedException('会话列表响应为空');
    try {
      final ids = body
          .map((item) => _requiredString(_requiredMap(item), 'id'))
          .toList(growable: false);
      final details = await Future.wait(ids.map(getConversation));
      return details
          .map(
            (detail) => ConversationSummary(
              id: detail.id,
              petId: detail.petId,
              title: detail.title,
              createdAt: detail.createdAt,
              updatedAt: detail.updatedAt,
            ),
          )
          .toList(growable: false);
    } on FormatException catch (error) {
      throw UnexpectedException('会话列表格式错误', cause: error);
    }
  }

  @override
  Future<AiChatResult> sendMessage({
    required String conversationId,
    required String message,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      'ai/chat',
      data: {'conversationId': conversationId, 'message': message.trim()},
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );
    final body = _requiredBody(response.data);
    try {
      final warningsValue = body['warnings'];
      final warnings = warningsValue is List
          ? warningsValue.map(_warningFromJson).toList(growable: false)
          : throw const FormatException('Expected warnings to be a list.');
      final meta = _requiredMap(body['meta']);
      return AiChatResult(
        answer: _requiredString(body, 'answer'),
        warnings: warnings,
        degraded: meta['degraded'] is bool ? meta['degraded'] as bool : false,
      );
    } on FormatException catch (error) {
      throw UnexpectedException('AI 回复格式错误', cause: error);
    }
  }

  ConversationDetail _detailFromJson(Map<String, dynamic> json) {
    try {
      final messages = _requiredList(json, 'messages')
          .map((item) {
            final message = _requiredMap(item);
            return ConversationMessage(
              id: _requiredString(message, 'id'),
              role: _requiredString(message, 'role'),
              content: _requiredString(message, 'content'),
              createdAt: _requiredDate(message, 'createdAt'),
            );
          })
          .toList(growable: false);
      return ConversationDetail(
        id: _requiredString(json, 'id'),
        petId: _requiredString(json, 'petId'),
        title: _nullableString(json, 'title'),
        createdAt: _requiredDate(json, 'createdAt'),
        updatedAt: _requiredDate(json, 'updatedAt'),
        messages: messages,
      );
    } on FormatException catch (error) {
      throw UnexpectedException('会话详情格式错误', cause: error);
    }
  }

  AiWarning _warningFromJson(dynamic value) {
    final json = _requiredMap(value);
    return AiWarning(
      code: _requiredString(json, 'code'),
      message: _requiredString(json, 'message'),
      degraded: json['degraded'] is bool ? json['degraded'] as bool : null,
    );
  }

  Map<String, dynamic> _requiredBody(Map<String, dynamic>? body) {
    if (body == null) throw const UnexpectedException('服务响应为空');
    return body;
  }

  Map<String, dynamic> _requiredMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    throw const FormatException('Expected an object.');
  }

  List<dynamic> _requiredList(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is List<dynamic>) return value;
    throw FormatException('Expected "$key" to be a list.');
  }

  String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw FormatException('Expected a non-empty string for "$key".');
  }

  String? _nullableString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null || value is String) return value as String?;
    throw FormatException('Expected a string or null for "$key".');
  }

  DateTime _requiredDate(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) throw FormatException('Expected a date for "$key".');
    final date = DateTime.tryParse(value);
    if (date == null) throw FormatException('Expected an ISO date for "$key".');
    return date.toLocal();
  }
}
