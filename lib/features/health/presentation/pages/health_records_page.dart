import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/route_paths.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../pets/application/pet_controller.dart';
import '../../../pets/application/pet_providers.dart';
import '../../application/health_controller.dart';
import '../../application/health_providers.dart';
import '../../domain/models/health_record.dart';

class HealthRecordsPage extends ConsumerStatefulWidget {
  const HealthRecordsPage({super.key});

  @override
  ConsumerState<HealthRecordsPage> createState() => _HealthRecordsPageState();
}

class _HealthRecordsPageState extends ConsumerState<HealthRecordsPage> {
  late final PetController _pets;
  late final HealthController _health;
  bool _shouldRefreshOnEntry = true;

  @override
  void initState() {
    super.initState();
    _pets = ref.read(petControllerProvider);
    _health = ref.read(healthControllerProvider);
    _pets.addListener(_loadCurrentPet);
    Future.microtask(() {
      _pets.load();
      _loadCurrentPet();
    });
  }

  @override
  void dispose() {
    _pets.removeListener(_loadCurrentPet);
    super.dispose();
  }

  void _loadCurrentPet() {
    final pet = _pets.currentPet;
    if (_pets.status == PetListStatus.ready && pet != null) {
      final force = _shouldRefreshOnEntry;
      _shouldRefreshOnEntry = false;
      _health.load(pet.id, force: force);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_pets, _health]),
    builder: (context, _) {
      if (_pets.status == PetListStatus.initial ||
          _pets.status == PetListStatus.loading) {
        return const AppLoadingView(message: '正在加载宠物档案…', animate: false);
      }
      if (_pets.status == PetListStatus.failure) {
        return AppErrorView(
          message: '无法加载宠物档案。',
          onRetry: () => _pets.load(force: true),
        );
      }
      final pet = _pets.currentPet;
      if (pet == null) {
        return AppEmptyView(
          title: '先创建宠物档案',
          message: '创建宠物后即可记录它的健康情况。',
          icon: Icons.pets_outlined,
          actionLabel: '创建宠物档案',
          onAction: () => context.go(AppRoutePaths.createPet),
        );
      }
      return Scaffold(
        appBar: AppBar(
          title: const Text('健康记录'),
          actions: [
            if (_pets.pets.length > 1)
              PopupMenuButton<String>(
                tooltip: '切换宠物',
                icon: const Icon(Icons.swap_horiz_rounded),
                onSelected: (id) => _pets.selectPet(id),
                itemBuilder: (context) => [
                  for (final item in _pets.pets)
                    PopupMenuItem(value: item.id, child: Text(item.name)),
                ],
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('add_health_record_button'),
          onPressed: () => context.go(AppRoutePaths.newHealthRecord),
          icon: const Icon(Icons.add_rounded),
          label: const Text('添加记录'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                '记录 ${pet.name} 的健康变化',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            _RecordFilters(controller: _health),
            Expanded(child: _recordsBody(context)),
          ],
        ),
      );
    },
  );

  Widget _recordsBody(BuildContext context) => switch (_health.status) {
    HealthRecordsStatus.initial || HealthRecordsStatus.loading =>
      const AppLoadingView(message: '正在加载健康记录…', animate: false),
    HealthRecordsStatus.failure => AppErrorView(
      message: '健康记录暂时无法加载。',
      onRetry: () {
        final pet = _pets.currentPet;
        if (pet != null) _health.load(pet.id, force: true);
      },
    ),
    HealthRecordsStatus.ready when _health.records.isEmpty =>
      const AppEmptyView(
        title: '还没有健康记录',
        message: '记录疫苗、用药、检查或日常变化，方便持续关注宠物健康。',
        icon: Icons.favorite_border_rounded,
      ),
    HealthRecordsStatus.ready when _health.visibleRecords.isEmpty =>
      AppEmptyView(
        title: '没有符合条件的记录',
        message: '可以调整类型或日期范围。',
        icon: Icons.filter_alt_off_outlined,
        actionLabel: '清除筛选',
        onAction: () {
          _health.setRecordTypeFilter(null);
          _health.setDateRange(null);
        },
      ),
    HealthRecordsStatus.ready => RefreshIndicator(
      onRefresh: () async {
        final pet = _pets.currentPet;
        if (pet != null) await _health.load(pet.id, force: true);
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: _health.visibleRecords.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _RecordCard(
          record: _health.visibleRecords[index],
          onOpen: () => context.go(
            AppRoutePaths.healthRecordDetails(_health.visibleRecords[index].id),
          ),
          onEdit: () => context.go(
            AppRoutePaths.editHealthRecord(_health.visibleRecords[index].id),
          ),
          onDelete: () => _confirmDelete(_health.visibleRecords[index]),
        ),
      ),
    ),
  };

  Future<void> _confirmDelete(HealthRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除这条记录？'),
        content: const Text('删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _health.delete(record.id);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('删除失败，请稍后重试。')));
      }
    }
  }
}

class _RecordFilters extends StatelessWidget {
  const _RecordFilters({required this.controller});

  final HealthController controller;

  static const _types = <(String, String)>[
    ('symptom', '症状'),
    ('vaccine', '疫苗'),
    ('medicine', '用药'),
    ('checkup', '检查'),
    ('weight', '体重'),
    ('diet', '饮食'),
  ];

  @override
  Widget build(BuildContext context) {
    final range = controller.dateRange;
    return SizedBox(
      height: 52,
      child: ListView(
        key: const Key('health_record_filters'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ChoiceChip(
            label: const Text('全部'),
            selected: controller.recordTypeFilter == null,
            onSelected: (_) => controller.setRecordTypeFilter(null),
          ),
          const SizedBox(width: 8),
          for (final item in _types) ...[
            ChoiceChip(
              label: Text(item.$2),
              selected: controller.recordTypeFilter == item.$1,
              onSelected: (_) => controller.setRecordTypeFilter(item.$1),
            ),
            const SizedBox(width: 8),
          ],
          ActionChip(
            avatar: const Icon(Icons.date_range_outlined, size: 18),
            label: Text(
              range == null
                  ? '日期'
                  : '${_shortDate(range.start)} - ${_shortDate(range.end)}',
            ),
            onPressed: () => _pickDateRange(context),
          ),
          if (range != null)
            IconButton(
              tooltip: '清除日期筛选',
              onPressed: () => controller.setDateRange(null),
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: controller.dateRange,
    );
    if (selected != null) controller.setDateRange(selected);
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });
  final HealthRecord record;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('health_record_card'),
    child: ListTile(
      onTap: onOpen,
      leading: CircleAvatar(child: Icon(_iconFor(record.recordType))),
      title: Text(
        record.displayTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${record.typeLabel} · ${_dateLabel(record.recordDate)}\n${record.description}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'edit', child: Text('编辑')),
          PopupMenuItem(value: 'delete', child: Text('删除')),
        ],
      ),
    ),
  );
}

IconData _iconFor(String type) => switch (type) {
  'symptom' => Icons.healing_outlined,
  'vaccine' => Icons.vaccines_outlined,
  'medicine' => Icons.medication_outlined,
  'checkup' => Icons.medical_services_outlined,
  'weight' => Icons.monitor_weight_outlined,
  'diet' => Icons.restaurant_outlined,
  _ => Icons.favorite_border_rounded,
};

String _dateLabel(DateTime date) =>
    '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

String _shortDate(DateTime date) => '${date.month}/${date.day}';
