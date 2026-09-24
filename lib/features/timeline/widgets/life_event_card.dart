import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../models/life_event.dart';
import '../../../widgets/common/emotion_score_badge.dart';
import '../../auth/providers/auth_providers.dart';
import '../../profile/providers/profile_providers.dart';

class LifeEventCard extends ConsumerWidget {
  final LifeEvent event;
  final VoidCallback? onTap;

  const LifeEventCard({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isOwnEvent = currentUser?.uid == event.authorId;
    final authorAsync =
        isOwnEvent ? null : ref.watch(userProfileProvider(event.authorId));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isOwnEvent)
                InkWell(
                  onTap: () => context.push('/user/${event.authorId}'),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          authorAsync?.valueOrNull?.displayName ?? '投稿者',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
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
                      child: Icon(Icons.bolt, color: Colors.amber, size: 18),
                    ),
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isOwnEvent && event.visibility != EventVisibility.public)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        event.visibility == EventVisibility.private ? Icons.lock_outline : Icons.group_outlined,
                        size: 14,
                        semanticLabel: event.visibility == EventVisibility.private ? '非公開' : 'フォロワー限定',
                      ),
                    ),
                  Text(
                    event.occurredYearMonth,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                event.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    label: Text(event.category, style: const TextStyle(fontSize: 11)),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 6),
                  EmotionScoreBadge(
                    emotionTag: event.emotionTag,
                    emotionScore: event.emotionScore,
                  ),
                  const Spacer(),
                  const Icon(Icons.favorite, size: 14, color: Colors.redAccent),
                  const SizedBox(width: 2),
                  Text('${event.likeCount}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 10),
                  const Icon(Icons.mode_comment_outlined, size: 14),
                  const SizedBox(width: 2),
                  Text('${event.commentCount}', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String formatDateTime(DateTime dt) => DateFormat('yyyy/MM/dd HH:mm').format(dt);
