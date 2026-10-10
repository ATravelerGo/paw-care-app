import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_providers.dart';
import '../features/auth/application/auth_session_controller.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import 'route_paths.dart';
import 'startup_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authSession = ref.watch(authSessionProvider);
  final router = GoRouter(
    initialLocation: AppRoutePaths.startup,
    refreshListenable: authSession,
    redirect: (context, state) => _redirect(authSession, state),
    routes: [
      GoRoute(
        path: AppRoutePaths.startup,
        builder: (context, state) => const StartupPage(),
      ),
      GoRoute(
        path: AppRoutePaths.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutePaths.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutePaths.home,
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}, name: 'routerProvider');

String? _redirect(AuthSessionController authSession, GoRouterState state) {
  final location = state.matchedLocation;

  return switch (authSession.status) {
    AuthSessionStatus.unknown =>
      location == AppRoutePaths.startup ? null : AppRoutePaths.startup,
    AuthSessionStatus.unauthenticated =>
      location == AppRoutePaths.login || location == AppRoutePaths.register
          ? null
          : AppRoutePaths.login,
    AuthSessionStatus.authenticated =>
      location == AppRoutePaths.startup ||
              location == AppRoutePaths.login ||
              location == AppRoutePaths.register
          ? AppRoutePaths.home
          : null,
  };
}
