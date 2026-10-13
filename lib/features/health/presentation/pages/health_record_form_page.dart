import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/route_paths.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../application/health_controller.dart';
import '../../application/health_providers.dart';
import '../../domain/models/health_record.dart';
import '../../domain/models/weight_trend.dart';

class HealthRecordFormPage extends ConsumerStatefulWidget {
  const HealthRecordFormPage({
    this.recordId,
    this.initialRecordType,
    super.key,
  });
  final String? recordId;
  final String? initialRecordType;

  @override
  ConsumerState<HealthRecordFormPage> createState() =>
      _HealthRecordFormPageState();
}

class _HealthRecordFormPageState extends ConsumerState<HealthRecordFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  String _type = 'symptom';
  DateTime _date = DateTime.now();
  bool _populated = false;

  static const _types = <(String, String)>[
    ('symptom', '症状'),
    ('vaccine', '疫苗'),
    ('medicine', '用药'),
    ('checkup', '检查'),
    ('weight', '体重'),
    ('diet', '饮食'),
  ];

  @override
  void initState() {
    super.initState();
    final initialRecordType = widget.initialRecordType;
    if (initialRecordType != null &&
        _types.any((item) => item.$1 == initialRecordType)) {
      _type = initialRecordType;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(healthControllerProvider);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final record = widget.recordId == null
            ? null
            : controller.recordById(widget.recordId!);
        if (widget.recordId != null &&
            record == null &&
            controller.status == HealthRecordsStatus.loading) {
          return Scaffold(
            appBar: AppBar(
              leading: AppBackButton(
                fallbackLocation: AppRoutePaths.healthRecordDetails(
                  widget.recordId!,
                ),
              ),
              title: const Text('编辑健康记录'),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (widget.recordId != null && record == null) {
          return Scaffold(
            appBar: AppBar(
              leading: AppBackButton(
                fallbackLocation: AppRoutePaths.healthRecordDetails(
                  widget.recordId!,
                ),
              ),
              title: const Text('编辑健康记录'),
            ),
            body: const Center(child: Text('找不到这条记录。')),
          );
        }
        _populate(record);
        return Scaffold(
          appBar: AppBar(
            leading: AppBackButton(
              fallbackLocation: widget.recordId == null
                  ? AppRoutePaths.health
                  : AppRoutePaths.healthRecordDetails(widget.recordId!),
            ),
            title: Text(widget.recordId == null ? '添加健康记录' : '编辑健康记录'),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                DropdownButtonFormField<String>(
                  key: const Key('health_record_type'),
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: '记录类型'),
                  items: [
                    for (final item in _types)
                      DropdownMenuItem(value: item.$1, child: Text(item.$2)),
                  ],
                  onChanged: controller.isSaving
                      ? null
                      : (value) => setState(() => _type = value!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('health_record_title'),
                  controller: _title,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '标题（可选）',
                    hintText: '例如：年度疫苗接种',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('health_record_description'),
                  controller: _description,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: '记录内容',
                    hintText: _type == 'weight'
                        ? '例如：5.2 kg'
                        : '描述症状、检查结果或日常变化',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请填写记录内容';
                    }
                    if (_type == 'weight' &&
                        parseWeightKilograms(value) == null) {
                      return '请输入有效体重，例如 5.2 kg';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('发生日期'),
                  subtitle: Text(_dateLabel(_date)),
                  trailing: const Icon(Icons.calendar_month_outlined),
                  onTap: controller.isSaving ? null : _pickDate,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('save_health_record_button'),
                  onPressed: controller.isSaving
                      ? null
                      : () => _save(controller),
                  child: controller.isSaving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.recordId == null ? '保存记录' : '保存修改'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _populate(HealthRecord? record) {
    if (_populated || record == null) return;
    _populated = true;
    _type = record.recordType;
    _title.text = record.title ?? '';
    _description.text = record.description;
    _date = record.recordDate;
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _save(HealthController controller) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final weight = _type == 'weight'
        ? parseWeightKilograms(_description.text)
        : null;
    try {
      await controller.save(
        HealthRecordDraft(
          recordType: _type,
          title: _title.text,
          description: _description.text,
          recordDate: _date,
          metadata: weight == null ? const {} : {'weight': weight},
        ),
        recordId: widget.recordId,
      );
      if (mounted) context.pop();
    } on Object catch (error) {
      if (!mounted) return;
      final message = error is AppException ? error.message : '保存失败，请稍后重试。';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

String _dateLabel(DateTime date) => '${date.year}年${date.month}月${date.day}日';
