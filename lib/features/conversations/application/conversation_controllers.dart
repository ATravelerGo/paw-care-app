import 'package:flutter/foundation.dart';

import '../domain/models/conversation.dart';
import '../domain/repositories/conversation_repository.dart';

enum ConversationListStatus { initial, loading, ready, failure }

final class ConversationListController extends ChangeNotifier {
  ConversationListController({required this.repository});

  final ConversationRepository repository;
  ConversationListStatus _status = ConversationListStatus.initial;
  List<ConversationSummary> _conversations = const [];
  String? _petId;
  Object? _error;
  bool _isCreating = false;
  bool _isDisposed = false;

  ConversationListStatus get status => _status;
  List<ConversationSummary> get conversations =>
      List.unmodifiable(_conversations);
  Object? get error => _error;
  bool get isCreating => _isCreating;
  String? get currentPetId => _petId;

  Future<void> loadForPet(String petId, {bool force = false}) async {
    if (_status == ConversationListStatus.loading ||
        (!force &&
            _status == ConversationListStatus.ready &&
            _petId == petId)) {
      return;
    }
    _petId = petId;
    _status = ConversationListStatus.loading;
    _error = null;
    _notify();
    try {
      _conversations = await repository.getConversationsForPet(petId);
      _status = ConversationListStatus.ready;
    } on Object catch (error) {
      _status = ConversationListStatus.failure;
      _error = error;
    }
    _notify();
  }

  Future<ConversationSummary> createForPet(String petId) async {
    if (_isCreating) throw StateError('Conversation creation is in progress.');
    _isCreating = true;
    _notify();
    try {
      final conversation = await repository.createConversation(petId);
      if (_petId == petId) {
        _conversations = [conversation, ..._conversations];
        _status = ConversationListStatus.ready;
      }
      return conversation;
    } finally {
      _isCreating = false;
      _notify();
    }
  }

  Future<void> delete(String conversationId) async {
    await repository.deleteConversation(conversationId);
    _conversations = _conversations
        .where((conversation) => conversation.id != conversationId)
        .toList(growable: false);
    _notify();
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

enum ConversationDetailStatus { loading, ready, failure }

final class ConversationDetailController extends ChangeNotifier {
  ConversationDetailController({
    required this.conversationId,
    required this.repository,
  });

  final String conversationId;
  final ConversationRepository repository;
  ConversationDetailStatus _status = ConversationDetailStatus.loading;
  ConversationDetail? _detail;
  Object? _error;
  bool _isSending = false;
  String? _failedMessage;
  bool _isDisposed = false;

  ConversationDetailStatus get status => _status;
  ConversationDetail? get detail => _detail;
  Object? get error => _error;
  bool get isSending => _isSending;
  String? get failedMessage => _failedMessage;

  Future<void> load() async {
    _status = ConversationDetailStatus.loading;
    _error = null;
    _notify();
    try {
      _detail = await repository.getConversation(conversationId);
      _status = ConversationDetailStatus.ready;
    } on Object catch (error) {
      _status = ConversationDetailStatus.failure;
      _error = error;
    }
    _notify();
  }

  Future<void> send(String message) async {
    final normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty || _isSending || _detail == null) return;
    _isSending = true;
    _failedMessage = null;
    final userMessage = ConversationMessage(
      id: 'pending-${DateTime.now().microsecondsSinceEpoch}',
      role: 'user',
      content: normalizedMessage,
      createdAt: DateTime.now(),
    );
    _detail = _copyWithMessages([..._detail!.messages, userMessage]);
    _notify();
    try {
      final result = await repository.sendMessage(
        conversationId: conversationId,
        message: normalizedMessage,
      );
      final assistantMessage = ConversationMessage(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        role: 'assistant',
        content: result.answer,
        createdAt: DateTime.now(),
        warnings: result.warnings,
        degraded: result.degraded,
      );
      _detail = _copyWithMessages([..._detail!.messages, assistantMessage]);
    } on Object catch (error) {
      _detail = _copyWithMessages(
        _detail!.messages.where((item) => item.id != userMessage.id).toList(),
      );
      _failedMessage = normalizedMessage;
      _error = error;
    } finally {
      _isSending = false;
      _notify();
    }
  }

  Future<void> retry() {
    final message = _failedMessage;
    return message == null ? Future.value() : send(message);
  }

  ConversationDetail _copyWithMessages(List<ConversationMessage> messages) {
    final detail = _detail!;
    return ConversationDetail(
      id: detail.id,
      petId: detail.petId,
      title: detail.title,
      createdAt: detail.createdAt,
      updatedAt: detail.updatedAt,
      messages: messages,
    );
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
