import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/route_paths.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../application/pet_controller.dart';
import '../../application/pet_providers.dart';
import '../../domain/models/pet.dart';

class PetListPage extends ConsumerStatefulWidget {
  const PetListPage({super.key});

  @override
  ConsumerState<PetListPage> createState() => _PetListPageState();
}

class _PetListPageState extends ConsumerState<PetListPage> {
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
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(
            fallbackLocation: AppRoutePaths.home,
            tooltip: '返回首页',
          ),
          title: const Text('我的宠物'),
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('create_pet_button'),
          onPressed: controller.isSaving
              ? null
              : () => context.push(AppRoutePaths.createPet),
          icon: const Icon(Icons.add_rounded),
          label: const Text('添加宠物'),
        ),
        body: _PetListBody(controller: controller),
      ),
    );
  }
}

class _PetListBody extends StatelessWidget {
  const _PetListBody({required this.controller});

  final PetController controller;

  @override
  Widget build(BuildContext context) {
    return switch (controller.status) {
      PetListStatus.initial || PetListStatus.loading => const AppLoadingView(),
      PetListStatus.failure => AppErrorView(
        onRetry: () => controller.load(force: true),
      ),
      PetListStatus.ready when controller.pets.isEmpty => AppEmptyView(
        title: '还没有宠物档案',
        message: '点击右下角添加第一只宠物。',
        icon: Icons.pets_outlined,
      ),
      PetListStatus.ready => RefreshIndicator(
        onRefresh: () => controller.load(force: true),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: controller.pets.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _PetListTile(
            pet: controller.pets[index],
            isCurrent: controller.currentPet?.id == controller.pets[index].id,
            onSelect: () => controller.selectPet(controller.pets[index].id),
          ),
        ),
      ),
    };
  }
}

class _PetListTile extends StatelessWidget {
  const _PetListTile({
    required this.pet,
    required this.isCurrent,
    required this.onSelect,
  });

  final Pet pet;
  final bool isCurrent;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => context.push(AppRoutePaths.petDetails(pet.id)),
        leading: CircleAvatar(child: const Icon(Icons.pets_rounded)),
        title: Text(pet.name),
        subtitle: Text(
          [pet.speciesLabel, pet.breed].whereType<String>().join(' · '),
        ),
        trailing: isCurrent
            ? const Chip(label: Text('当前'))
            : TextButton(onPressed: onSelect, child: const Text('设为当前')),
      ),
    );
  }
}
