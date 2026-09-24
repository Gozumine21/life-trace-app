import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/common/app_image.dart';
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
            tooltip: '設定',
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
                            ? AppImage(url: profile!.iconUrl!).toImageProvider()
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                  child: Row(
                    children: [
                      const Text(
                        '自分のライフライン',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Spacer(),
                      if (eventsAsync.asData?.value case final events? when events.isNotEmpty)
                        Text(
                          '${events.length}件の記録・転機${events.where((e) => e.isTurningPoint).length}件',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ),
              eventsAsync.when(
                data: (events) {
                  if (events.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyView(
                        message: 'まだライフイベントがありません。\n入学・就職・引っ越しなど、\n心に残っている出来事から書いてみましょう。',
                        icon: Icons.auto_stories_outlined,
                        actionLabel: '最初の記録をする',
                        actionIcon: Icons.edit_note,
                        onAction: () => context.push('/life-event/new'),
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
                error: (e, st) => SliverToBoxAdapter(
                  child: ErrorView(error: e, onRetry: () => ref.invalidate(userLifeEventsProvider(user.uid))),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          );
        },
        loading: () => const LoadingView(),
        error: (e, st) => ErrorView(error: e, onRetry: () => ref.invalidate(currentUserProfileProvider)),
      ),
    );
  }
}
