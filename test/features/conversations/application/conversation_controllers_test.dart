import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care_app/core/error/app_exception.dart';
import 'package:paw_care_app/features/conversations/application/conversation_controllers.dart';
import 'package:paw_care_app/features/conversations/domain/models/conversation.dart';

import '../../../helpers/fake_conversation_repository.dart';

void main() {
  final conversation = ConversationSummary(
    id: 'conversation-a',
    petId: 'pet-a',
    createdAt: DateTime(2026, 10, 13),
    updatedAt: DateTime(2026, 10, 13),
  );
  final detail = ConversationDetail(
    id: 'conversation-a',
    petId: 'pet-a',
    createdAt: DateTime(2026, 10, 13),
    updatedAt: DateTime(2026, 10, 13),
    messages: const [],
  );

  test(
    'loads only conversations for the current pet and creates a new one',
    () async {
      final repository = FakeConversationRepository(
        conversations: [
          conversation,
          ConversationSummary(
            id: 'conversation-b',
            petId: 'pet-b',
            createdAt: DateTime(2026, 10, 12),
            updatedAt: DateTime(2026, 10, 12),
          ),
        ],
      );
      final controller = ConversationListController(repository: repository);
      addTearDown(controller.dispose);

      await controller.loadForPet('pet-a');
      final created = await controller.createForPet('pet-a');

      expect(controller.status, ConversationListStatus.ready);
      expect(
        controller.conversations.map((item) => item.petId),
        everyElement('pet-a'),
      );
      expect(created.petId, 'pet-a');
      expect(repository.lastPetId, 'pet-a');
    },
  );

  test('adds an AI reply and warnings after a successful send', () async {
    final repository = FakeConversationRepository(
      detail: detail,
      chatResult: const AiChatResult(
        answer: '请先观察精神和饮水情况。',
        warnings: [AiWarning(code: 'PARTIAL_RESULT', message: '知识库暂不可用')],
        degraded: true,
      ),
    );
    final controller = ConversationDetailController(
      conversationId: detail.id,
      repository: repository,
    );
    addTearDown(controller.dispose);
    await controller.load();

    await controller.send('今天有点没精神');

    expect(repository.lastMessage, '今天有点没精神');
    expect(controller.detail!.messages, hasLength(2));
    final answer = controller.detail!.messages.last;
    expect(answer.content, '请先观察精神和饮水情况。');
    expect(answer.degraded, isTrue);
    expect(answer.warnings.single.message, '知识库暂不可用');
  });

  test('keeps failed content available for retry', () async {
    final repository = FakeConversationRepository(detail: detail)
      ..error = const NetworkException('网络不可用');
    final controller = ConversationDetailController(
      conversationId: detail.id,
      repository: repository,
    );
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.status, ConversationDetailStatus.failure);

    repository.error = null;
    await controller.load();
    repository.error = const NetworkException('网络不可用');
    await controller.send('呕吐了一次');

    expect(controller.failedMessage, '呕吐了一次');
    expect(controller.detail!.messages, isEmpty);
  });
}
