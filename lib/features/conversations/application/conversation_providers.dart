import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../data/data_sources/conversation_remote_data_source.dart';
import '../data/repositories/conversation_repository_impl.dart';
import '../domain/repositories/conversation_repository.dart';
import 'conversation_controllers.dart';

final conversationRemoteDataSourceProvider =
    Provider<ConversationRemoteDataSource>(
      (ref) => ApiConversationRemoteDataSource(ref.watch(apiClientProvider)),
      name: 'conversationRemoteDataSourceProvider',
    );

final conversationRepositoryProvider = Provider<ConversationRepository>(
  (ref) => ConversationRepositoryImpl(
    ref.watch(conversationRemoteDataSourceProvider),
  ),
  name: 'conversationRepositoryProvider',
);

final conversationListControllerProvider = Provider<ConversationListController>(
  (ref) {
    final controller = ConversationListController(
      repository: ref.watch(conversationRepositoryProvider),
    );
    ref.onDispose(controller.dispose);
    return controller;
  },
  name: 'conversationListControllerProvider',
);

final conversationDetailControllerProvider = Provider.autoDispose
    .family<ConversationDetailController, String>((ref, conversationId) {
      final controller = ConversationDetailController(
        conversationId: conversationId,
        repository: ref.watch(conversationRepositoryProvider),
      );
      ref.onDispose(controller.dispose);
      return controller;
    }, name: 'conversationDetailControllerProvider');
