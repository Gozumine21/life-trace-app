import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/constants.dart';
import '../../../models/life_event.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/life_event_providers.dart';

/// 「いいね」「わかる」「感動した」から、気持ちに近いものを1つ送るボタン群。
///
/// 選んだものをもう一度押すと取り消せる。別のものを押すと切り替わる。
class ReactionBar extends ConsumerWidget {
  final LifeEvent event;

  const ReactionBar({super.key, required this.event});

  static String _meaning(String type) {
    switch (type) {
      case ReactionType.empathy:
        return '自分にも似た経験や気持ちがある';
      case ReactionType.moved:
        return '自分にはない経験に心を動かされた';
      default:
        return '読んでよかった、応援したい';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final myReaction = ref.watch(myReactionProvider(event.eventId)).valueOrNull;
    final isOwner = currentUser?.uid == event.authorId;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final type in ReactionType.all)
          Tooltip(
            message: _meaning(type),
            child: FilterChip(
              label: Text('${ReactionType.emojiFor(type)} ${ReactionType.labelFor(type)}'),
              selected: myReaction?.type == type,
              onSelected: currentUser == null || isOwner
                  ? null
                  : (_) => ref.read(lifeEventControllerProvider.notifier).toggleReaction(
                        event.eventId,
                        myReaction?.type == type,
                        type,
                        eventAuthorId: event.authorId,
                      ),
            ),
          ),
        Text(
          '${event.likeCount}人が気持ちを送りました',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
