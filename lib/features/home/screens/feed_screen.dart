import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/common/empty_view.dart';
import '../../../widgets/common/error_view.dart';
import '../../../widgets/common/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../../moderation/providers/moderation_providers.dart';
import '../../timeline/providers/life_event_providers.dart';
import '../../timeline/widgets/life_event_card.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(publicFeedProvider);
    final blockedIds = ref.watch(blockedUserIdsProvider).asData?.value ?? const [];
    final user = ref.watch(currentUserProvider);
    // まだ1件も記録していない人には、最初の一歩を案内する。
    final hasNoOwnEvents = user != null &&
        (ref.watch(userLifeEventsProvider(user.uid)).asData?.value.isEmpty ?? false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LifeTrace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: '使い方ガイド',
            onPressed: () => context.push('/guide'),
          ),
        ],
      ),
      body: feed.when(
        data: (allEvents) {
          final events =
              allEvents.where((e) => !blockedIds.contains(e.authorId)).toList();
          if (events.isEmpty) {
            return Column(
              children: [
                if (hasNoOwnEvents) const _GettingStartedCard(),
                Expanded(
                  child: EmptyView(
                    message: 'まだ公開されているライフイベントがありません。\nあなたの物語を最初に投稿してみませんか？',
                    icon: Icons.auto_stories_outlined,
                    actionLabel: 'ライフイベントを記録する',
                    actionIcon: Icons.edit_note,
                    onAction: () => context.push('/life-event/new'),
                  ),
                ),
              ],
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(publicFeedProvider),
            child: ListView.builder(
              // 下部の「記録する」ボタンに最後のカードが隠れないよう余白をとる。
              padding: const EdgeInsets.only(top: 8, bottom: 96),
              itemCount: events.length + (hasNoOwnEvents ? 1 : 0),
              itemBuilder: (context, index) {
                if (hasNoOwnEvents) {
                  if (index == 0) return const _GettingStartedCard();
                  index -= 1;
                }
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

class _GettingStartedCard extends StatelessWidget {
  const _GettingStartedCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'はじめての方へ',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            for (final step in const [
              '① 「記録する」から、人生の出来事を1つ書いてみましょう',
              '② マイページの「感情グラフ」で気持ちの移り変わりを振り返れます',
              '③ 気になる人のライフラインを読んで、気持ちを伝えましょう',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  step,
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimaryContainer),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => context.push('/life-event/new'),
                  icon: const Icon(Icons.edit_note),
                  label: const Text('最初の記録をする'),
                ),
                TextButton(
                  onPressed: () => context.push('/guide'),
                  child: const Text('使い方を見る'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
