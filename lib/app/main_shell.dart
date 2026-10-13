import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_providers.dart';
import '../features/auth/application/auth_session_controller.dart';
import 'route_paths.dart';

class MainShell extends ConsumerWidget {
  const MainShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authSession = ref.read(authSessionProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _selectedIndex(location);

    return ListenableBuilder(
      listenable: authSession,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(_titles[selectedIndex]),
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
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) => context.go(_paths[index]),
          destinations: const [
            NavigationDestination(
              key: Key('nav_home'),
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: '首页',
            ),
            NavigationDestination(
              key: Key('nav_health'),
              icon: Icon(Icons.favorite_border_rounded),
              selectedIcon: Icon(Icons.favorite_rounded),
              label: '健康',
            ),
            NavigationDestination(
              key: Key('nav_ai'),
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome_rounded),
              label: 'AI',
            ),
            NavigationDestination(
              key: Key('nav_gallery'),
              icon: Icon(Icons.photo_library_outlined),
              selectedIcon: Icon(Icons.photo_library_rounded),
              label: '相册',
            ),
            NavigationDestination(
              key: Key('nav_profile'),
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: '我的',
            ),
          ],
        ),
      ),
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

const _paths = [
  AppRoutePaths.home,
  AppRoutePaths.health,
  AppRoutePaths.ai,
  AppRoutePaths.gallery,
  AppRoutePaths.profile,
];

const _titles = ['PawCare', '健康记录', 'PawCare AI', '宠物相册', '我的'];

int _selectedIndex(String location) {
  final index = _paths.indexOf(location);
  return index < 0 ? 0 : index;
}
