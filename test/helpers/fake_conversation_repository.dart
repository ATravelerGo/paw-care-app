import 'package:paw_care_app/features/conversations/domain/models/conversation.dart';
import 'package:paw_care_app/features/conversations/domain/repositories/conversation_repository.dart';

final class FakeConversationRepository implements ConversationRepository {
  FakeConversationRepository({
    this.conversations = const [],
    this.detail,
    this.chatResult = const AiChatResult(
      answer: 'AI 回复',
      warnings: [],
      degraded: false,
    ),
  });

  List<ConversationSummary> conversations;
  ConversationDetail? detail;
  AiChatResult chatResult;
  Object? error;
  int getConversationsCalls = 0;
  int createCalls = 0;
  int sendCalls = 0;
  String? lastPetId;
  String? lastMessage;

  @override
  Future<ConversationSummary> createConversation(String petId) async {
    createCalls++;
    final currentError = error;
    if (currentError != null) throw currentError;
    final conversation = ConversationSummary(
      id: 'new-conversation',
      petId: petId,
      createdAt: DateTime(2026, 10, 13),
      updatedAt: DateTime(2026, 10, 13),
    );
    conversations = [conversation, ...conversations];
    return conversation;
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    conversations = conversations
        .where((conversation) => conversation.id != conversationId)
        .toList();
  }

  @override
  Future<ConversationDetail> getConversation(String conversationId) async {
    final currentError = error;
    if (currentError != null) throw currentError;
    final value = detail;
    if (value == null) throw StateError('Detail is not configured.');
    return value;
  }

  @override
  Future<List<ConversationSummary>> getConversationsForPet(String petId) async {
    getConversationsCalls++;
    lastPetId = petId;
    final currentError = error;
    if (currentError != null) throw currentError;
    return conversations
        .where((conversation) => conversation.petId == petId)
        .toList(growable: false);
  }

  @override
  Future<AiChatResult> sendMessage({
    required String conversationId,
    required String message,
  }) async {
    sendCalls++;
    lastMessage = message;
    final currentError = error;
    if (currentError != null) throw currentError;
    return chatResult;
  }
}
