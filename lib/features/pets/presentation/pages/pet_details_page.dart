import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/route_paths.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../application/pet_controller.dart';
import '../../application/pet_providers.dart';
import '../../domain/models/pet.dart';

class PetDetailsPage extends ConsumerStatefulWidget {
  const PetDetailsPage({required this.petId, super.key});

  final String petId;

  @override
  ConsumerState<PetDetailsPage> createState() => _PetDetailsPageState();
}

class _PetDetailsPageState extends ConsumerState<PetDetailsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(petControllerProvider).load());
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(petControllerProvider);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final pet = controller.petById(widget.petId);
        return Scaffold(
          appBar: AppBar(
            leading: const AppBackButton(
              fallbackLocation: AppRoutePaths.pets,
              tooltip: '返回宠物列表',
            ),
            title: const Text('宠物详情'),
            actions: [
              if (pet != null)
                IconButton(
                  tooltip: '编辑',
                  onPressed: controller.isSaving
                      ? null
                      : () => context.push(AppRoutePaths.editPet(pet.id)),
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
          body: _DetailsBody(
            controller: controller,
            pet: pet,
            onDelete: pet == null ? null : () => _deletePet(controller, pet),
          ),
        );
      },
    );
  }

  Future<void> _deletePet(PetController controller, Pet pet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除宠物档案？'),
        content: Text('“${pet.name}”的健康记录也会一并删除。'),
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
    if (confirmed != true) return;
    try {
      await controller.deletePet(pet.id);
      if (mounted) context.go(AppRoutePaths.pets);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error is AppException ? error.message : '删除失败，请稍后重试。'),
        ),
      );
    }
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({
    required this.controller,
    required this.pet,
    required this.onDelete,
  });

  final PetController controller;
  final Pet? pet;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    if (pet == null && controller.status == PetListStatus.loading) {
      return const AppLoadingView();
    }
    if (pet == null) {
      return const AppEmptyView(
        title: '未找到宠物档案',
        message: '它可能已被删除，或不属于当前账户。',
        icon: Icons.search_off_rounded,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: CircleAvatar(
            radius: 48,
            child: const Icon(Icons.pets_rounded, size: 42),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            pet!.name,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 28),
        _InfoRow(label: '种类', value: pet!.speciesLabel),
        _InfoRow(label: '品种', value: pet!.breed ?? '未填写'),
        _InfoRow(label: '性别', value: _genderLabel(pet!.gender)),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: controller.isSaving ? null : onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('删除宠物档案'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 72, child: Text(label)),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
    );
  }
}

String _genderLabel(String? value) => switch (value) {
  'male' => '男孩',
  'female' => '女孩',
  _ => '未填写',
};
