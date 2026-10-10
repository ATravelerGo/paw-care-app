import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/auth_providers.dart';
import '../../../auth/application/auth_session_controller.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authSession = ref.read(authSessionProvider);

    return ListenableBuilder(
      listenable: authSession,
      builder: (context, _) {
        final user = authSession.currentUser;
        final nickname = user?.nickname?.trim();
        final displayName = nickname != null && nickname.isNotEmpty
            ? nickname
            : user?.email ?? 'PawCare 用户';

        return Scaffold(
          appBar: AppBar(
            title: const Text('PawCare'),
            actions: [
              IconButton(
                key: const Key('logout_button'),
                tooltip: '退出登录',
                onPressed: authSession.isLoggingOut
                    ? null
                    : () => _logout(authSession),
                icon: authSession.isLoggingOut
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.pets_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '你好，$displayName',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '登录认证已经完成，接下来可以创建宠物档案。',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout(AuthSessionController authSession) async {
    try {
      await authSession.logout();
    } on Object {
      // The login page displays any secure-storage cleanup error.
    }
  }
}
