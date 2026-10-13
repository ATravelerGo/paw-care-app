import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/route_paths.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../pets/application/pet_controller.dart';
import '../../../pets/application/pet_providers.dart';
import '../../application/health_controller.dart';
import '../../application/health_providers.dart';
import '../../domain/models/weight_trend.dart';
import '../widgets/weight_trend_chart.dart';

class WeightTrendPage extends ConsumerStatefulWidget {
  const WeightTrendPage({super.key});

  @override
  ConsumerState<WeightTrendPage> createState() => _WeightTrendPageState();
}

class _WeightTrendPageState extends ConsumerState<WeightTrendPage> {
  late final PetController _pets;
  late final HealthController _health;
  WeightTrendRange _range = WeightTrendRange.days90;

  @override
  void initState() {
    super.initState();
    _pets = ref.read(petControllerProvider);
    _health = ref.read(healthControllerProvider);
    _pets.addListener(_loadRecords);
    Future.microtask(() async {
      await _pets.load();
      _loadRecords();
    });
  }

  @override
  void dispose() {
    _pets.removeListener(_loadRecords);
    super.dispose();
  }

  void _loadRecords() {
    final pet = _pets.currentPet;
    if (_pets.status == PetListStatus.ready && pet != null) {
      _health.load(pet.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_pets, _health]),
      builder: (context, _) {
        final pet = _pets.currentPet;
        return Scaffold(
          appBar: AppBar(
            leading: const AppBackButton(
              fallbackLocation: AppRoutePaths.health,
              tooltip: '返回健康记录',
            ),
            title: const Text('体重趋势'),
          ),
          floatingActionButton: pet == null
              ? null
              : FloatingActionButton.extended(
                  key: const Key('add_weight_record_button'),
                  onPressed: () => context.push(
                    AppRoutePaths.newHealthRecordForType('weight'),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('记录体重'),
                ),
          body: _body(pet?.name),
        );
      },
    );
  }

  Widget _body(String? petName) {
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
    if (petName == null) {
      return AppEmptyView(
        title: '先创建宠物档案',
        message: '创建宠物后即可查看体重趋势。',
        icon: Icons.pets_outlined,
        actionLabel: '创建宠物档案',
        onAction: () => context.push(AppRoutePaths.createPet),
      );
    }
    if (_health.status == HealthRecordsStatus.initial ||
        _health.status == HealthRecordsStatus.loading) {
      return const AppLoadingView(message: '正在整理体重记录…', animate: false);
    }
    if (_health.status == HealthRecordsStatus.failure) {
      return AppErrorView(
        message: '体重记录暂时无法加载。',
        onRetry: () {
          final pet = _pets.currentPet;
          if (pet != null) _health.load(pet.id, force: true);
        },
      );
    }

    final trend = WeightTrendData.fromRecords(_health.records, range: _range);
    return RefreshIndicator(
      onRefresh: () async {
        final pet = _pets.currentPet;
        if (pet != null) await _health.load(pet.id, force: true);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Text('$petName 的体重变化', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<WeightTrendRange>(
              key: const Key('weight_range_selector'),
              segments: [
                for (final range in WeightTrendRange.values)
                  ButtonSegment(value: range, label: Text(range.label)),
              ],
              selected: {_range},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  setState(() => _range = selection.single),
            ),
          ),
          const SizedBox(height: 20),
          if (trend.latest != null) _SummaryCard(trend: trend),
          if (trend.latest != null) const SizedBox(height: 16),
          if (trend.points.length >= 2)
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                child: WeightTrendChart(points: trend.points),
              ),
            )
          else
            _InsufficientDataCard(pointCount: trend.points.length),
          if (trend.hasAnomaly) ...[
            const SizedBox(height: 12),
            const _NoticeCard(
              icon: Icons.warning_amber_rounded,
              message: '红色数据点与上一条记录相比变化达到 20%，请确认录入的数值和单位是否正确。',
            ),
          ],
          if (trend.unreadableRecordCount > 0) ...[
            const SizedBox(height: 12),
            _NoticeCard(
              icon: Icons.info_outline_rounded,
              message:
                  '有 ${trend.unreadableRecordCount} 条体重记录无法识别数值，请使用“5.2 kg”这样的格式。',
            ),
          ],
          if (trend.points.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('近期记录', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final point in trend.points.reversed.take(5))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  point.isAnomalous
                      ? Icons.warning_amber_rounded
                      : Icons.monitor_weight_outlined,
                ),
                title: Text('${point.kilograms.toStringAsFixed(1)} kg'),
                subtitle: Text(_dateLabel(point.date)),
              ),
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.trend});

  final WeightTrendData trend;

  @override
  Widget build(BuildContext context) {
    final change = trend.change;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _SummaryItem(
                label: '最近体重',
                value: '${trend.latest!.kilograms.toStringAsFixed(1)} kg',
              ),
            ),
            if (change != null) ...[
              const SizedBox(height: 48, child: VerticalDivider()),
              Expanded(
                child: _SummaryItem(
                  label: '区间变化',
                  value:
                      '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} kg',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 6),
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }
}

class _InsufficientDataCard extends StatelessWidget {
  const _InsufficientDataCard({required this.pointCount});

  final int pointCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.show_chart_rounded, size: 42),
            const SizedBox(height: 12),
            Text(
              pointCount == 0 ? '当前范围内还没有体重记录' : '再记录一次即可生成趋势图',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text('趋势图至少需要两条可识别的体重记录。', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(leading: Icon(icon), title: Text(message)),
    );
  }
}

String _dateLabel(DateTime date) => '${date.year}年${date.month}月${date.day}日';
