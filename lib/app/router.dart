import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_providers.dart';
import '../features/auth/application/auth_session_controller.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/conversations/presentation/pages/conversation_detail_page.dart';
import '../features/conversations/presentation/pages/conversation_list_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/home/presentation/pages/module_placeholder_page.dart';
import '../features/health/presentation/pages/health_record_form_page.dart';
import '../features/health/presentation/pages/health_record_detail_page.dart';
import '../features/health/presentation/pages/health_records_page.dart';
import '../features/pets/presentation/pages/pet_details_page.dart';
import '../features/pets/presentation/pages/pet_form_page.dart';
import '../features/pets/presentation/pages/pet_list_page.dart';
import 'route_paths.dart';
import 'main_shell.dart';
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
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutePaths.home,
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: AppRoutePaths.health,
            builder: (context, state) => const HealthRecordsPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const HealthRecordFormPage(),
              ),
              GoRoute(
                path: ':recordId/edit',
                builder: (context, state) => HealthRecordFormPage(
                  recordId: state.pathParameters['recordId'],
                ),
              ),
              GoRoute(
                path: ':recordId',
                builder: (context, state) => HealthRecordDetailPage(
                  recordId: state.pathParameters['recordId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutePaths.ai,
            builder: (context, state) => const ConversationListPage(),
          ),
          GoRoute(
            path: AppRoutePaths.gallery,
            builder: (context, state) => const ModulePlaceholderPage(
              title: '宠物相册即将开放',
              message: '后续可以在这里记录每一个成长瞬间。',
              icon: Icons.photo_library_outlined,
            ),
          ),
          GoRoute(
            path: AppRoutePaths.profile,
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutePaths.pets,
        builder: (context, state) => const PetListPage(),
      ),
      GoRoute(
        path: AppRoutePaths.createPet,
        builder: (context, state) => const PetFormPage(),
      ),
      GoRoute(
        path: '/pets/:petId/edit',
        builder: (context, state) =>
            PetFormPage(petId: state.pathParameters['petId']),
      ),
      GoRoute(
        path: '/pets/:petId',
        builder: (context, state) =>
            PetDetailsPage(petId: state.pathParameters['petId']!),
      ),
      GoRoute(
        path: '/ai/conversations/:conversationId',
        builder: (context, state) => ConversationDetailPage(
          conversationId: state.pathParameters['conversationId']!,
        ),
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
