import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/route_paths.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../pets/application/pet_controller.dart';
import '../../../pets/application/pet_providers.dart';
import '../../application/conversation_controllers.dart';
import '../../application/conversation_providers.dart';
import '../../domain/models/conversation.dart';

class ConversationListPage extends ConsumerStatefulWidget {
  const ConversationListPage({super.key});

  @override
  ConsumerState<ConversationListPage> createState() =>
      _ConversationListPageState();
}

class _ConversationListPageState extends ConsumerState<ConversationListPage> {
  late final PetController _petController;
  late final ConversationListController _conversationController;

  @override
  void initState() {
    super.initState();
    _petController = ref.read(petControllerProvider);
    _conversationController = ref.read(conversationListControllerProvider);
    _petController.addListener(_loadForCurrentPet);
    Future.microtask(() {
      _petController.load();
      _loadForCurrentPet();
    });
  }

  @override
  void dispose() {
    _petController.removeListener(_loadForCurrentPet);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_petController, _conversationController]),
      builder: (context, _) {
        final pet = _petController.currentPet;
        if (_petController.status == PetListStatus.loading ||
            _petController.status == PetListStatus.initial) {
          return const AppLoadingView(message: '正在加载宠物档案…', animate: false);
        }
        if (_petController.status == PetListStatus.failure) {
          return AppErrorView(
            message: '无法确认当前宠物，请稍后重试。',
            onRetry: () => _petController.load(force: true),
          );
        }
        if (pet == null) {
          return AppEmptyView(
            title: '先创建宠物档案',
            message: 'AI 会围绕当前宠物提供健康建议。',
            icon: Icons.pets_outlined,
            actionLabel: '创建宠物档案',
            onAction: () => context.push(AppRoutePaths.createPet),
          );
        }
        return _ConversationListBody(
          petName: pet.name,
          controller: _conversationController,
          onCreate: () => _createConversation(pet.id),
          onDelete: _deleteConversation,
        );
      },
    );
  }

  void _loadForCurrentPet() {
    final pet = _petController.currentPet;
    if (_petController.status == PetListStatus.ready && pet != null) {
      _conversationController.loadForPet(pet.id);
    }
  }

  Future<void> _createConversation(String petId) async {
    try {
      final conversation = await _conversationController.createForPet(petId);
      if (mounted) {
        context.push(AppRoutePaths.conversationDetails(conversation.id));
      }
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('创建会话失败，请稍后重试。')));
    }
  }

  Future<void> _deleteConversation(ConversationSummary conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除这段会话？'),
        content: const Text('会话消息将无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await _conversationController.delete(conversation.id);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('删除会话失败，请稍后重试。')));
    }
  }
}

class _ConversationListBody extends StatelessWidget {
  const _ConversationListBody({
    required this.petName,
    required this.controller,
    required this.onCreate,
    required this.onDelete,
  });

  final String petName;
  final ConversationListController controller;
  final VoidCallback onCreate;
  final ValueChanged<ConversationSummary> onDelete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('new_conversation_button'),
        onPressed: controller.isCreating ? null : onCreate,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('新建会话'),
      ),
      body: switch (controller.status) {
        ConversationListStatus.initial || ConversationListStatus.loading =>
          const AppLoadingView(message: '正在加载会话…', animate: false),
        ConversationListStatus.failure => AppErrorView(
          message: '会话暂时无法加载，请稍后重试。',
          onRetry: () =>
              controller.loadForPet(controller.currentPetId ?? '', force: true),
        ),
        ConversationListStatus.ready when controller.conversations.isEmpty =>
          AppEmptyView(
            title: '和 $petName 聊聊吧',
            message: '可以告诉 AI 它今天的饮食、精神和身体变化。',
            icon: Icons.auto_awesome_outlined,
            actionLabel: '新建会话',
            onAction: onCreate,
          ),
        ConversationListStatus.ready => RefreshIndicator(
          onRefresh: () =>
              controller.loadForPet(controller.currentPetId!, force: true),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: controller.conversations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final conversation = controller.conversations[index];
              return Card(
                child: ListTile(
                  onTap: () => context.push(
                    AppRoutePaths.conversationDetails(conversation.id),
                  ),
                  leading: const CircleAvatar(
                    child: Icon(Icons.auto_awesome_rounded),
                  ),
                  title: Text(conversation.displayTitle),
                  subtitle: Text(_formatDate(conversation.updatedAt)),
                  trailing: IconButton(
                    tooltip: '删除会话',
                    onPressed: () => onDelete(conversation),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ),
              );
            },
          ),
        ),
      },
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
