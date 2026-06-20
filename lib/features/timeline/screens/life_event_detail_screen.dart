import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/constants.dart';
import '../../../widgets/common/emotion_score_badge.dart';
import '../../../widgets/common/error_view.dart';
import '../../../widgets/common/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
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

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(lifeEventProvider(widget.eventId));
    final commentsAsync = ref.watch(eventCommentsProvider(widget.eventId));
    final myReactionAsync = ref.watch(myReactionProvider(widget.eventId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ライフイベント詳細')),
      body: eventAsync.when(
        data: (event) {
          if (event == null) {
            return const Center(child: Text('このライフイベントは見つかりませんでした'));
          }
          final isOwner = currentUser?.uid == event.authorId;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
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
                            child: Image.network(
                              event.imageUrls[i],
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
                        const SizedBox(width: 12),
                        if (isOwner)
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => context.push('/life-event/${event.eventId}/edit'),
                          ),
                        if (isOwner)
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
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
                                      child: const Text('削除'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await ref
                                    .read(lifeEventControllerProvider.notifier)
                                    .deleteLifeEvent(widget.eventId);
                                if (context.mounted) context.pop();
                              }
                            },
                          ),
                      ],
                    ),
                    const Divider(height: 32),
                    const Text('コメント', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    commentsAsync.when(
                      data: (comments) {
                        if (comments.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('まだコメントはありません'),
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
                      error: (e, st) => ErrorView(error: e),
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
                          decoration: const InputDecoration(
                            hintText: 'コメントを入力',
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () async {
                          final text = _commentController.text.trim();
                          if (text.isEmpty) return;
                          await ref
                              .read(lifeEventControllerProvider.notifier)
                              .addComment(widget.eventId, text);
                          _commentController.clear();
                        },
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
        loading: () => const LoadingView(),
        error: (e, st) => ErrorView(error: e),
      ),
    );
  }
}
