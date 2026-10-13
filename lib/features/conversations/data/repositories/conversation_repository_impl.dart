import '../../domain/models/conversation.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../data_sources/conversation_remote_data_source.dart';

final class ConversationRepositoryImpl implements ConversationRepository {
  ConversationRepositoryImpl(this._remoteDataSource);

  final ConversationRemoteDataSource _remoteDataSource;

  @override
  Future<ConversationSummary> createConversation(String petId) =>
      _remoteDataSource.createConversation(petId);

  @override
  Future<void> deleteConversation(String conversationId) =>
      _remoteDataSource.deleteConversation(conversationId);

  @override
  Future<ConversationDetail> getConversation(String conversationId) =>
      _remoteDataSource.getConversation(conversationId);

  @override
  Future<List<ConversationSummary>> getConversationsForPet(String petId) async {
    final conversations = await _remoteDataSource.getConversations();
    return conversations
        .where((conversation) => conversation.petId == petId)
        .toList(growable: false);
  }

  @override
  Future<AiChatResult> sendMessage({
    required String conversationId,
    required String message,
  }) => _remoteDataSource.sendMessage(
    conversationId: conversationId,
    message: message,
  );
}
