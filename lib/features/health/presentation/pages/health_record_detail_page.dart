import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/route_paths.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../application/health_providers.dart';

class HealthRecordDetailPage extends ConsumerWidget {
  const HealthRecordDetailPage({required this.recordId, super.key});

  final String recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(healthControllerProvider);
    final record = controller.recordById(recordId);
    if (record == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(
            fallbackLocation: AppRoutePaths.health,
            tooltip: '返回健康记录',
          ),
          title: const Text('健康记录详情'),
        ),
        body: const Center(child: Text('找不到这条记录。')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(
          fallbackLocation: AppRoutePaths.health,
          tooltip: '返回健康记录',
        ),
        title: const Text('健康记录详情'),
        actions: [
          IconButton(
            tooltip: '编辑记录',
            onPressed: () =>
                context.push(AppRoutePaths.editHealthRecord(record.id)),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Chip(label: Text(record.typeLabel)),
                  const SizedBox(height: 12),
                  Text(
                    record.displayTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(_dateLabel(record.recordDate)),
                  const Divider(height: 32),
                  Text(
                    record.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _dateLabel(DateTime date) => '${date.year}年${date.month}月${date.day}日';
