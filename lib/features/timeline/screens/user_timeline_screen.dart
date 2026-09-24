import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/report.dart';
import '../../../widgets/common/empty_view.dart';
import '../../../widgets/common/error_view.dart';
import '../../../widgets/common/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../../moderation/providers/moderation_providers.dart';
import '../../moderation/widgets/report_dialog.dart';
import '../../profile/providers/profile_providers.dart';
import '../providers/life_event_providers.dart';
import '../widgets/life_event_card.dart';

class UserTimelineScreen extends ConsumerWidget {
  final String uid;

  const UserTimelineScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(uid));
    final eventsAsync = ref.watch(visibleUserLifeEventsProvider(uid));
    final isFollowingAsync = ref.watch(isFollowingProvider(uid));
    final currentUser = ref.watch(currentUserProvider);
    final isSelf = currentUser?.uid == uid;
    final isBlocked = ref.watch(isUserBlockedProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: profileAsync.when(
          data: (p) => Text(p?.displayName ?? 'ライフライン'),
          loading: () => const Text('ライフライン'),
          error: (e, st) => const Text('ライフライン'),
        ),
        actions: [
          if (!isSelf) ...[
            PopupMenuButton<String>(
              tooltip: 'その他の操作',
              onSelected: (value) async {
                if (value == 'block') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(isBlocked ? 'ブロックを解除しますか？' : 'ブロックしますか？'),
                      content: isBlocked
                          ? null
                          : const Text('ブロックすると、このユーザーの投稿がフィード・検索から表示されなくなります。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(isBlocked ? '解除する' : 'ブロックする'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref
                        .read(blockControllerProvider.notifier)
                        .toggleBlock(uid, isBlocked);
                  }
                } else if (value == 'report') {
                  showReportDialog(
                    context: context,
                    ref: ref,
                    targetType: ReportTargetType.user,
                    targetId: uid,
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'block',
                  child: Text(isBlocked ? 'ブロックを解除' : 'ブロックする'),
                ),
                const PopupMenuItem(value: 'report', child: Text('ユーザーを通報')),
              ],
            ),
          ],
        ],
      ),
      body: isBlocked
          ? _BlockedPlaceholder(
              onUnblock: () => ref
                  .read(blockControllerProvider.notifier)
                  .toggleBlock(uid, true),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: Column(
                    children: [
                      if (profileAsync.valueOrNull?.bio case final bio? when bio.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(bio, style: Theme.of(context).textTheme.bodyMedium),
                          ),
                        ),
                      if (!isSelf)
                        isFollowingAsync.when(
                          data: (isFollowing) => SizedBox(
                            width: double.infinity,
                            child: isFollowing
                                ? FilledButton.tonalIcon(
                                    onPressed: () => ref
                                        .read(followControllerProvider.notifier)
                                        .toggleFollow(uid, isFollowing),
                                    icon: const Icon(Icons.check),
                                    label: const Text('フォロー中（タップで解除）'),
                                  )
                                : FilledButton.icon(
                                    onPressed: () => ref
                                        .read(followControllerProvider.notifier)
                                        .toggleFollow(uid, isFollowing),
                                    icon: const Icon(Icons.person_add_alt),
                                    label: const Text('フォローする'),
                                  ),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (e, st) => const SizedBox.shrink(),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => context.push('/experience/$uid'),
                              icon: const Icon(Icons.menu_book_outlined),
                              label: const Text('追体験する'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => context.push('/emotion-graph/$uid'),
                              icon: const Icon(Icons.show_chart),
                              label: const Text('感情グラフ'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: eventsAsync.when(
                    data: (events) {
                      final following = isFollowingAsync.valueOrNull ?? false;
                      if (events.isEmpty) {
                        return EmptyView(
                          message: following || isSelf
                              ? '公開されているライフイベントはありません'
                              : '公開されているライフイベントはありません。\nフォローすると、フォロワー限定の記録も読めるようになります。',
                        );
                      }
                      return ListView.builder(
                        itemCount: events.length + (following || isSelf ? 0 : 1),
                        itemBuilder: (context, index) {
                          if (index == events.length) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'フォローすると、この人のフォロワー限定の記録も読めるようになります。',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          final event = events[index];
                          return LifeEventCard(
                            event: event,
                            onTap: () => context.push('/life-event/${event.eventId}'),
                          );
                        },
                      );
                    },
                    loading: () => const LoadingView(),
                    error: (e, st) => ErrorView(
                      error: e,
                      onRetry: () => ref.invalidate(userLifeEventsProvider(uid)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _BlockedPlaceholder extends StatelessWidget {
  final VoidCallback onUnblock;

  const _BlockedPlaceholder({required this.onUnblock});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('このユーザーをブロックしています。\n投稿は表示されません。', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onUnblock, child: const Text('ブロックを解除する')),
          ],
        ),
      ),
    );
  }
}
