import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/route_paths.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../application/home_controller.dart';
import '../../application/home_providers.dart';
import '../../domain/models/health_record_summary.dart';
import '../../../pets/application/pet_controller.dart';
import '../../../pets/application/pet_providers.dart';
import '../../../pets/domain/models/pet.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final PetController _petController;
  late final HomeController _homeController;

  @override
  void initState() {
    super.initState();
    _petController = ref.read(petControllerProvider);
    _homeController = ref.read(homeControllerProvider);
    _petController.addListener(_syncSummary);
    Future.microtask(() {
      _petController.load();
      _syncSummary();
    });
  }

  @override
  void dispose() {
    _petController.removeListener(_syncSummary);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_petController, _homeController]),
      builder: (context, _) => _HomeBody(
        petController: _petController,
        homeController: _homeController,
      ),
    );
  }

  void _syncSummary() {
    final pet = _petController.currentPet;
    if (_petController.status != PetListStatus.ready || pet == null) {
      _homeController.clear();
      return;
    }
    _homeController.loadForPet(pet.id);
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.petController, required this.homeController});

  final PetController petController;
  final HomeController homeController;

  @override
  Widget build(BuildContext context) {
    return switch (petController.status) {
      PetListStatus.initial || PetListStatus.loading => const AppLoadingView(
        message: '正在加载宠物档案…',
        animate: false,
      ),
      PetListStatus.failure => AppErrorView(
        message: '宠物档案暂时无法加载，请稍后重试。',
        onRetry: () => petController.load(force: true),
      ),
      PetListStatus.ready when petController.currentPet == null => AppEmptyView(
        title: '先创建第一只宠物吧',
        message: '创建后，健康记录和 AI 问诊都会围绕它展开。',
        icon: Icons.pets_outlined,
        actionLabel: '创建宠物档案',
        onAction: () => context.push(AppRoutePaths.createPet),
      ),
      PetListStatus.ready => _PetHomeOverview(
        pet: petController.currentPet!,
        homeController: homeController,
        onRefresh: () async {
          await petController.load(force: true);
          final pet = petController.currentPet;
          if (pet != null) await homeController.loadForPet(pet.id, force: true);
        },
      ),
    };
  }
}

class _PetHomeOverview extends StatelessWidget {
  const _PetHomeOverview({
    required this.pet,
    required this.homeController,
    required this.onRefresh,
  });

  final Pet pet;
  final HomeController homeController;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _PetCard(pet: pet),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  key: const Key('ask_ai_action'),
                  icon: Icons.auto_awesome_rounded,
                  label: '问 AI',
                  onTap: () => context.go(AppRoutePaths.ai),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  key: const Key('add_health_record_action'),
                  icon: Icons.add_chart_rounded,
                  label: '添加健康记录',
                  onTap: () => context.go(AppRoutePaths.health),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Text('最近健康记录', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              TextButton(
                onPressed: () => context.go(AppRoutePaths.health),
                child: const Text('查看全部'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _RecentRecords(controller: homeController),
        ],
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutePaths.pets),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 30,
                child: Icon(Icons.pets_rounded, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        pet.speciesLabel,
                        pet.breed,
                      ].whereType<String>().join(' · '),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.swap_horiz_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _RecentRecords extends StatelessWidget {
  const _RecentRecords({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return switch (controller.status) {
      HomeSummaryStatus.idle || HomeSummaryStatus.loading => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(value: 0.5)),
      ),
      HomeSummaryStatus.failure => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '暂时无法加载健康记录，可下拉页面重试。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
      HomeSummaryStatus.ready when controller.recentRecords.isEmpty => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.favorite_border_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '还没有健康记录，记录一次日常情况吧。',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
      HomeSummaryStatus.ready => Card(
        child: Column(
          children: [
            for (final record in controller.recentRecords)
              _HealthRecordTile(record: record),
          ],
        ),
      ),
    };
  }
}

class _HealthRecordTile extends StatelessWidget {
  const _HealthRecordTile({required this.record});

  final HealthRecordSummary record;

  @override
  Widget build(BuildContext context) {
    final date = record.recordDate;
    final formattedDate =
        '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.favorite_rounded)),
      title: Text(
        record.displayTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('${record.typeLabel} · $formattedDate'),
      onTap: () => context.go(AppRoutePaths.health),
    );
  }
}
