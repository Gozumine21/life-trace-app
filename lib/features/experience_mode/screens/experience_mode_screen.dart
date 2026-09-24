import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/life_age.dart';
import '../../../models/life_event.dart';
import '../../../widgets/common/app_image.dart';
import '../../../widgets/common/emotion_score_badge.dart';
import '../../../widgets/common/empty_view.dart';
import '../../../widgets/common/error_view.dart';
import '../../../widgets/common/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../../timeline/providers/life_event_providers.dart';
import '../../timeline/widgets/reaction_bar.dart';

class ExperienceModeScreen extends ConsumerStatefulWidget {
  final String uid;

  const ExperienceModeScreen({super.key, required this.uid});

  @override
  ConsumerState<ExperienceModeScreen> createState() => _ExperienceModeScreenState();
}

class _ExperienceModeScreenState extends ConsumerState<ExperienceModeScreen> {
  final _pageController = PageController();

  /// 転機としてマークされた出来事だけをたどるか。
  bool _turningPointsOnly = false;
  bool _recordedFirstView = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _recordView(String eventId) {
    final viewer = ref.read(currentUserProvider);
    if (viewer == null || viewer.uid == widget.uid) return;
    ref.read(firestoreServiceProvider).recordExperienceView(
          viewerId: viewer.uid,
          targetUserId: widget.uid,
          eventId: eventId,
        ).catchError((_) {});
  }

  void _setTurningPointsOnly(bool value) {
    setState(() => _turningPointsOnly = value);
    if (_pageController.hasClients) _pageController.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(visibleUserLifeEventsProvider(widget.uid));
    final profile = ref.watch(userProfileProvider(widget.uid)).valueOrNull;
    final isSelf = ref.watch(currentUserProvider)?.uid == widget.uid;
    final hasTurningPoints = eventsAsync.valueOrNull?.any((e) => e.isTurningPoint) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(profile == null ? '追体験モード' : '${profile.displayName} の追体験'),
        actions: [
          if (hasTurningPoints)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: const Icon(Icons.bolt, color: Colors.amber, size: 18),
                label: const Text('転機だけ'),
                tooltip: '人生の分かれ道になった出来事だけをたどる',
                selected: _turningPointsOnly,
                onSelected: _setTurningPointsOnly,
              ),
            ),
        ],
      ),
      body: eventsAsync.when(
        data: (allEvents) {
          final events = _turningPointsOnly
              ? allEvents.where((e) => e.isTurningPoint).toList()
              : allEvents;
          if (events.isEmpty) {
            return const EmptyView(message: '追体験できるライフイベントがありません');
          }
          // 最初のページは onPageChanged が呼ばれないため、表示した時点で記録する。
          if (!_recordedFirstView) {
            _recordedFirstView = true;
            WidgetsBinding.instance.addPostFrameCallback((_) => _recordView(events.first.eventId));
          }
          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: events.length,
            onPageChanged: (index) => _recordView(events[index].eventId),
            itemBuilder: (context, index) => _ExperiencePage(
              event: events[index],
              index: index,
              total: events.length,
              birthYearMonth: profile?.birthYearMonth,
              canRespond: !isSelf,
            ),
          );
        },
        loading: () => const LoadingView(),
        error: (e, st) => ErrorView(error: e, onRetry: () => ref.invalidate(userLifeEventsProvider(widget.uid))),
      ),
    );
  }
}

class _ExperiencePage extends StatelessWidget {
  final LifeEvent event;
  final int index;
  final int total;
  final String? birthYearMonth;
  final bool canRespond;

  const _ExperiencePage({
    required this.event,
    required this.index,
    required this.total,
    required this.birthYearMonth,
    required this.canRespond,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isLast = index == total - 1;
    final ageLabel = LifeAge.label(birthYearMonth: birthYearMonth, occurredYearMonth: event.occurredYearMonth);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: (index + 1) / total,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text('${index + 1} / $total', style: textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                ageLabel == null ? event.occurredYearMonth : '${event.occurredYearMonth}・$ageLabel',
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              if (event.isTurningPoint) ...[
                const SizedBox(width: 8),
                const Icon(Icons.bolt, color: Colors.amber, size: 18),
                Text('転機', style: textTheme.labelMedium),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(event.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Chip(
                label: Text('${LifeEventCategories.emojiFor(event.category)} ${event.category}'),
                visualDensity: VisualDensity.compact,
              ),
              EmotionScoreBadge(emotionTag: event.emotionTag, emotionScore: event.emotionScore),
            ],
          ),
          const SizedBox(height: 16),
          if (event.imageUrls.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AppImage(url: event.imageUrls.first, height: 200, fit: BoxFit.cover, width: double.infinity),
            ),
            const SizedBox(height: 16),
          ],
          Text(event.body, style: const TextStyle(fontSize: 16, height: 1.6)),
          const SizedBox(height: 24),
          if (canRespond) ...[
            Text('この出来事に気持ちを送る', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            ReactionBar(event: event),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => context.push('/life-event/${event.eventId}'),
                  icon: const Icon(Icons.mode_comment_outlined),
                  label: Text('コメント（${event.commentCount}）'),
                ),
                TextButton.icon(
                  onPressed: () => context.push('/life-event/new?respondTo=${event.eventId}'),
                  icon: const Icon(Icons.reply),
                  label: const Text('似た経験を記録する'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Icon(
                  isLast ? Icons.flag_outlined : Icons.keyboard_double_arrow_up,
                  color: colorScheme.outline,
                ),
                Text(
                  isLast ? '最後まで読みました' : '上にスワイプして次の出来事へ',
                  style: textTheme.bodySmall,
                ),
                if (isLast && canRespond) ...[
                  const SizedBox(height: 8),
                  Text(
                    'あなたにも似た出来事はありましたか？',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: () => context.push('/life-event/new'),
                    icon: const Icon(Icons.edit_note),
                    label: const Text('自分の経験を記録する'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
