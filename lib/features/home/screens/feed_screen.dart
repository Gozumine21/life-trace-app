import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/common/empty_view.dart';
import '../../../widgets/common/error_view.dart';
import '../../../widgets/common/loading_view.dart';
import '../../moderation/providers/moderation_providers.dart';
import '../../timeline/providers/life_event_providers.dart';
import '../../timeline/widgets/life_event_card.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(publicFeedProvider);
    final blockedIds = ref.watch(blockedUserIdsProvider).asData?.value ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('LifeTrace')),
      body: feed.when(
        data: (allEvents) {
          final events =
              allEvents.where((e) => !blockedIds.contains(e.authorId)).toList();
          if (events.isEmpty) {
            return const EmptyView(
              message: 'まだ公開されているライフイベントがありません',
              icon: Icons.auto_stories_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(publicFeedProvider),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return LifeEventCard(
                  event: event,
                  onTap: () => context.push('/life-event/${event.eventId}'),
                );
              },
            ),
          );
        },
        loading: () => const LoadingView(),
        error: (e, st) => ErrorView(error: e, onRetry: () => ref.invalidate(publicFeedProvider)),
      ),
    );
  }
}
