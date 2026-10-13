import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/route_paths.dart';
import '../../../../shared/widgets/app_state_view.dart';

class ModulePlaceholderPage extends StatelessWidget {
  const ModulePlaceholderPage({
    required this.title,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.actionPath,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final String? actionPath;

  @override
  Widget build(BuildContext context) {
    return AppEmptyView(
      title: title,
      message: message,
      icon: icon,
      actionLabel: actionLabel,
      onAction: actionPath == null ? null : () => context.go(actionPath!),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.pets_rounded)),
            title: const Text('宠物档案'),
            subtitle: const Text('创建、切换和管理宠物'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutePaths.pets),
          ),
        ),
      ],
    );
  }
}
