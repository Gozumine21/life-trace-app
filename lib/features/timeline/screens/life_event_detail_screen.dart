import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/constants.dart';
import '../../../models/report.dart';
import '../../../widgets/common/app_image.dart';
import '../../../widgets/common/emotion_score_badge.dart';
import '../../../widgets/common/error_view.dart';
import '../../../widgets/common/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../../moderation/widgets/report_dialog.dart';
import '../../profile/providers/profile_providers.dart';
import '../providers/life_event_providers.dart';
import '../widgets/life_event_card.dart';

class LifeEventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const LifeEventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<LifeEventDetailScreen> createState() => _LifeEventDetailScreenState();
}

class _LifeEventDetailScreenState extends ConsumerState<LifeEventDetailScreen> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(lifeEventControllerProvider.notifier).addComment(widget.eventId, text);
      _commentController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(content: Text('コメントを送信できませんでした。もう一度お試しください。')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(lifeEventProvider(widget.eventId));
    final commentsAsync = ref.watch(eventCommentsProvider(widget.eventId));
    final myReactionAsync = ref.watch(myReactionProvider(widget.eventId));
    final currentUser = ref.watch(currentUserProvider);

    final loadedEvent = eventAsync.valueOrNull;
    final isOwnerOfLoadedEvent =
        loadedEvent != null && currentUser?.uid == loadedEvent.authorId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ライフイベント'),
        actions: [
          if (loadedEvent != null && !isOwnerOfLoadedEvent && currentUser != null)
            IconButton(
              icon: const Icon(Icons.flag_outlined),
              tooltip: '通報する',
              onPressed: () => showReportDialog(
                context: context,
                ref: ref,
                targetType: ReportTargetType.lifeEvent,
                targetId: loadedEvent.eventId,
                eventId: loadedEvent.eventId,
              ),
            ),
        ],
      ),
      body: eventAsync.when(
        data: (event) {
          if (event == null) {
            return const Center(child: Text('このライフイベントは見つかりませんでした'));
          }
          final isOwner = currentUser?.uid == event.authorId;
          final authorAsync = ref.watch(userProfileProvider(event.authorId));
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (!isOwner)
                      InkWell(
                        onTap: () => context.push('/user/${event.authorId}'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                authorAsync.valueOrNull?.displayName ?? '投稿者を見る',
                                style: const TextStyle(
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        if (event.isTurningPoint)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(Icons.bolt, color: Colors.amber),
                          ),
                        Expanded(
                          child: Text(
                            event.title,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(label: Text(event.occurredYearMonth)),
                        Chip(label: Text(event.category)),
                        EmotionScoreBadge(
                          emotionTag: event.emotionTag,
                          emotionScore: event.emotionScore,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(event.body, style: const TextStyle(fontSize: 16, height: 1.5)),
                    if (event.imageUrls.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 160,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: event.imageUrls.length,
                          separatorBuilder: (context, _) => const SizedBox(width: 8),
                          itemBuilder: (context, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AppImage(
                              url: event.imageUrls[i],
                              width: 160,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        myReactionAsync.when(
                          data: (reaction) => OutlinedButton.icon(
                            onPressed: currentUser == null
                                ? null
                                : () => ref
                                    .read(lifeEventControllerProvider.notifier)
                                    .toggleReaction(
                                      widget.eventId,
                                      reaction != null,
                                      ReactionType.like,
                                    ),
                            icon: Icon(
                              reaction != null ? Icons.favorite : Icons.favorite_border,
                              color: Colors.redAccent,
                            ),
                            label: Text('いいね ${event.likeCount}'),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (e, st) => const SizedBox.shrink(),
                        ),
                        const Spacer(),
                        if (isOwner)
                          TextButton.icon(
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('編集'),
                            onPressed: () => context.push('/life-event/${event.eventId}/edit'),
                          ),
                        if (isOwner)
                          TextButton.icon(
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('削除'),
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('削除しますか？'),
                                  content: const Text('このライフイベントを削除します。元に戻せません。'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('キャンセル'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('削除する'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                try {
                                  await ref
                                      .read(lifeEventControllerProvider.notifier)
                                      .deleteLifeEvent(widget.eventId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('ライフイベントを削除しました')),
                                    );
                                    context.pop();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('削除に失敗しました: $e')),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                      ],
                    ),
                    const Divider(height: 32),
                    Text(
                      'コメント（${event.commentCount}件）',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    commentsAsync.when(
                      data: (comments) {
                        if (comments.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('まだコメントはありません。最初の感想を送ってみましょう。'),
                          );
                        }
                        return Column(
                          children: comments
                              .map(
                                (c) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(child: Icon(Icons.person, size: 18)),
                                  title: Text(c.body),
                                  subtitle: Text(formatDateTime(c.createdAt)),
                                ),
                              )
                              .toList(),
                        );
                      },
                      loading: () => const LoadingView(),
                      error: (e, st) => ErrorView(
                        error: e,
                        onRetry: () => ref.invalidate(eventCommentsProvider(widget.eventId)),
                      ),
                    ),
                  ],
                ),
              ),
              if (currentUser != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    8,
                    12,
                    8 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: '感想やはげましを送る',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      ValueListenableBuilder(
                        valueListenable: _commentController,
                        builder: (context, value, _) => IconButton.filled(
                          icon: const Icon(Icons.send),
                          tooltip: 'コメントを送信',
                          onPressed: value.text.trim().isEmpty ? null : _sendComment,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
        loading: () => const LoadingView(),
        error: (e, st) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(lifeEventProvider(widget.eventId)),
        ),
      ),
    );
  }
}
