import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/constants.dart';
import '../../../core/utils/life_age.dart';
import '../../../models/life_event.dart';
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
import '../widgets/reaction_bar.dart';

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

  Future<void> _sendComment(String eventAuthorId) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(lifeEventControllerProvider.notifier)
          .addComment(widget.eventId, text, eventAuthorId: eventAuthorId);
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
          final follows = event == null
              ? false
              : ref.watch(isFollowingProvider(event.authorId)).valueOrNull ?? false;
          if (event == null ||
              !event.isVisibleTo(currentUser?.uid, viewerFollowsAuthor: follows)) {
            return const Center(child: Text('このライフイベントは見つからないか、公開されていません'));
          }
          final isOwner = currentUser?.uid == event.authorId;
          final authorAsync = ref.watch(userProfileProvider(event.authorId));
          final ageLabel = LifeAge.label(
            birthYearMonth: authorAsync.valueOrNull?.birthYearMonth,
            occurredYearMonth: event.occurredYearMonth,
          );
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
                        Chip(
                          label: Text(
                            ageLabel == null
                                ? event.occurredYearMonth
                                : '${event.occurredYearMonth}（$ageLabel）',
                          ),
                        ),
                        Chip(label: Text('${LifeEventCategories.emojiFor(event.category)} ${event.category}')),
                        if (isOwner)
                          Chip(
                            avatar: Icon(_visibilityIcon(event.visibility), size: 16),
                            label: Text(VisibilityOption.labelFor(event.visibility.name)),
                          ),
                        EmotionScoreBadge(
                          emotionTag: event.emotionTag,
                          emotionScore: event.emotionScore,
                        ),
                      ],
                    ),
                    if (event.respondsToEventId != null)
                      _RespondsToLink(eventId: event.respondsToEventId!),
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
                    ReactionBar(event: event),
                    if (!isOwner && currentUser != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/life-event/new?respondTo=${event.eventId}'),
                        icon: const Icon(Icons.reply),
                        label: const Text('この記録に応えて、自分の経験を記録する'),
                      ),
                    ],
                    Row(
                      children: [
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
                                      const SnackBar(content: Text('削除できませんでした。通信環境を確認して、もう一度お試しください。')),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                      ],
                    ),
                    _ResponsesSection(eventId: event.eventId),
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
                                (c) => _CommentTile(
                                  authorId: c.authorId,
                                  body: c.body,
                                  createdAt: c.createdAt,
                                  isEventAuthor: c.authorId == event.authorId,
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
                          decoration: InputDecoration(
                            hintText: isOwner ? '届いたコメントに返信する' : WritingGuide.commentHint,
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
                          onPressed:
                              value.text.trim().isEmpty ? null : () => _sendComment(event.authorId),
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

IconData _visibilityIcon(EventVisibility visibility) {
  switch (visibility) {
    case EventVisibility.public:
      return Icons.public;
    case EventVisibility.followers:
      return Icons.group_outlined;
    case EventVisibility.private:
      return Icons.lock_outline;
  }
}

/// 「この記録は〇〇に応えて書かれました」の表示。
class _RespondsToLink extends ConsumerWidget {
  final String eventId;

  const _RespondsToLink({required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final original = ref.watch(lifeEventProvider(eventId)).valueOrNull;
    final viewerId = ref.watch(currentUserProvider)?.uid;
    if (original == null || !original.isVisibleTo(viewerId, viewerFollowsAuthor: false)) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      color: colorScheme.secondaryContainer,
      child: ListTile(
        leading: const Icon(Icons.reply),
        title: Text('「${original.title}」に応えて書かれた記録です'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/life-event/${original.eventId}'),
      ),
    );
  }
}

/// この記録に応えて書かれた記録の一覧。
class _ResponsesSection extends ConsumerWidget {
  final String eventId;

  const _ResponsesSection({required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responses = ref.watch(responsesProvider(eventId)).valueOrNull ?? const [];
    if (responses.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Text(
          'この記録に応えた経験（${responses.length}件）',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '同じような出来事を、別の人はこう経験しました。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        for (final response in responses)
          LifeEventCard(
            event: response,
            onTap: () => context.push('/life-event/${response.eventId}'),
          ),
      ],
    );
  }
}

class _CommentTile extends ConsumerWidget {
  final String authorId;
  final String body;
  final DateTime createdAt;
  final bool isEventAuthor;

  const _CommentTile({
    required this.authorId,
    required this.body,
    required this.createdAt,
    required this.isEventAuthor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(userProfileProvider(authorId)).valueOrNull?.displayName ?? 'ユーザー';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Icons.person, size: 18)),
      title: Text(body),
      subtitle: Text('${isEventAuthor ? '$name（投稿者）' : name} ・ ${formatDateTime(createdAt)}'),
      onTap: () => context.push('/user/$authorId'),
    );
  }
}
