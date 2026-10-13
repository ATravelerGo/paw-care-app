import '../models/conversation.dart';

abstract interface class ConversationRepository {
  Future<List<ConversationSummary>> getConversationsForPet(String petId);

  Future<ConversationSummary> createConversation(String petId);

  Future<ConversationDetail> getConversation(String conversationId);

  Future<AiChatResult> sendMessage({
    required String conversationId,
    required String message,
  });

  Future<void> deleteConversation(String conversationId);
}
