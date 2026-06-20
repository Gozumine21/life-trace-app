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

class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const LoadingView();
    final profileAsync = ref.watch(currentUserProfileProvider);
    final eventsAsync = ref.watch(userLifeEventsProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('マイページ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: profile?.iconUrl != null
                            ? NetworkImage(profile!.iconUrl!)
                            : null,
                        child: profile?.iconUrl == null
                            ? const Icon(Icons.person, size: 32)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.displayName ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'フォロワー ${profile?.followerCount ?? 0}　フォロー中 ${profile?.followingCount ?? 0}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/profile/edit'),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('プロフィール編集'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              context.push('/emotion-graph/${user.uid}'),
                          icon: const Icon(Icons.show_chart),
                          label: const Text('感情グラフ'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    '自分のライフライン',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              eventsAsync.when(
                data: (events) {
                  if (events.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyView(
                        message: 'まだライフイベントがありません。\n右下の＋から追加しましょう。',
                        icon: Icons.auto_stories_outlined,
                      ),
                    );
                  }
                  return SliverList.builder(
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
                loading: () => const SliverToBoxAdapter(child: LoadingView()),
                error: (e, st) => SliverToBoxAdapter(child: ErrorView(error: e)),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
        loading: () => const LoadingView(),
        error: (e, st) => ErrorView(error: e),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/life-event/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
