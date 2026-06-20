import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/common/empty_view.dart';
import '../../../widgets/common/error_view.dart';
import '../../../widgets/common/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../providers/life_event_providers.dart';
import '../widgets/life_event_card.dart';

class UserTimelineScreen extends ConsumerWidget {
  final String uid;

  const UserTimelineScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(uid));
    final eventsAsync = ref.watch(userLifeEventsProvider(uid));
    final isFollowingAsync = ref.watch(isFollowingProvider(uid));
    final currentUser = ref.watch(currentUserProvider);
    final isSelf = currentUser?.uid == uid;

    return Scaffold(
      appBar: AppBar(
        title: profileAsync.when(
          data: (p) => Text(p?.displayName ?? 'ライフライン'),
          loading: () => const Text('ライフライン'),
          error: (e, st) => const Text('ライフライン'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: '追体験モード',
            onPressed: () => context.push('/experience/$uid'),
          ),
          IconButton(
            icon: const Icon(Icons.show_chart),
            tooltip: '感情グラフ',
            onPressed: () => context.push('/emotion-graph/$uid'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!isSelf)
            Padding(
              padding: const EdgeInsets.all(12),
              child: isFollowingAsync.when(
                data: (isFollowing) => SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () => ref
                        .read(followControllerProvider.notifier)
                        .toggleFollow(uid, isFollowing),
                    child: Text(isFollowing ? 'フォロー中' : 'フォローする'),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (e, st) => const SizedBox.shrink(),
              ),
            ),
          Expanded(
            child: eventsAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return const EmptyView(message: '公開されているライフイベントはありません');
                }
                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return LifeEventCard(
                      event: event,
                      onTap: () => context.push('/life-event/${event.eventId}'),
                    );
                  },
                );
              },
              loading: () => const LoadingView(),
              error: (e, st) => ErrorView(error: e),
            ),
          ),
        ],
      ),
    );
  }
}
