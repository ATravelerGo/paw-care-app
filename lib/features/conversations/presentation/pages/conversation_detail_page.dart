import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/route_paths.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../application/conversation_controllers.dart';
import '../../application/conversation_providers.dart';
import '../../domain/models/conversation.dart';

class ConversationDetailPage extends ConsumerStatefulWidget {
  const ConversationDetailPage({required this.conversationId, super.key});

  final String conversationId;

  @override
  ConsumerState<ConversationDetailPage> createState() =>
      _ConversationDetailPageState();
}

class _ConversationDetailPageState
    extends ConsumerState<ConversationDetailPage> {
  final _inputController = TextEditingController();
  late final ConversationDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(
      conversationDetailControllerProvider(widget.conversationId),
    );
    Future.microtask(_controller.load);
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(
      conversationDetailControllerProvider(widget.conversationId),
    );
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: '返回会话列表',
            onPressed: () => context.go(AppRoutePaths.conversations),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(controller.detail?.title ?? '健康咨询'),
        ),
        body: _DetailBody(controller: controller),
        bottomNavigationBar: controller.detail == null
            ? null
            : _MessageComposer(
                controller: _inputController,
                isSending: controller.isSending,
                onSend: _send,
              ),
      ),
    );
  }

  Future<void> _send() async {
    final message = _inputController.text;
    if (message.trim().isEmpty) return;
    _inputController.clear();
    await _controller.send(message);
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.controller});

  final ConversationDetailController controller;

  @override
  Widget build(BuildContext context) {
    return switch (controller.status) {
      ConversationDetailStatus.loading => const AppLoadingView(
        message: '正在加载消息…',
        animate: false,
      ),
      ConversationDetailStatus.failure => AppErrorView(
        message: '无法加载这段会话。',
        onRetry: controller.load,
      ),
      ConversationDetailStatus.ready => Column(
        children: [
          if (controller.failedMessage != null)
            _RetryBanner(controller: controller),
          Expanded(
            child: controller.detail!.messages.isEmpty
                ? const AppEmptyView(
                    title: '开始和 AI 聊聊吧',
                    message: '描述宠物的饮食、精神或身体变化，AI 会提供健康建议。',
                    icon: Icons.auto_awesome_outlined,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.detail!.messages.length,
                    itemBuilder: (context, index) => _MessageBubble(
                      message: controller.detail!.messages[index],
                    ),
                  ),
          ),
        ],
      ),
    };
  }
}

class _RetryBanner extends StatelessWidget {
  const _RetryBanner({required this.controller});

  final ConversationDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        title: const Text('消息发送失败'),
        trailing: TextButton(
          onPressed: controller.retry,
          child: const Text('重试'),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ConversationMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: isUser ? 'user_message' : 'assistant_message',
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          key: Key(isUser ? 'user_message' : 'assistant_message'),
          constraints: const BoxConstraints(maxWidth: 320),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUser
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message.content),
              if (message.degraded || message.warnings.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  message.degraded ? '部分能力暂不可用' : '提示',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                for (final warning in message.warnings)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      warning.message,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('chat_input_field'),
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => isSending ? null : onSend(),
                decoration: const InputDecoration(hintText: '说说宠物的情况…'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              key: const Key('chat_send_button'),
              tooltip: '发送',
              onPressed: isSending ? null : onSend,
              icon: isSending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
