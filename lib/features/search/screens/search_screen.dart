import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/constants.dart';
import '../../../widgets/common/empty_view.dart';
import '../../../widgets/common/error_view.dart';
import '../../../widgets/common/loading_view.dart';
import '../../timeline/widgets/life_event_card.dart';
import '../providers/search_providers.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  static const _decades = [10, 20, 30, 40, 50, 60];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final notifier = ref.read(searchQueryProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    final header = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: TextField(
          decoration: const InputDecoration(
            labelText: 'キーワードで絞り込む（任意）',
            hintText: '例: 受験、転職、結婚',
            prefixIcon: Icon(Icons.search),
          ),
          textInputAction: TextInputAction.search,
          onChanged: notifier.setKeyword,
        ),
      ),
      _FilterLabel('今の状況から探す'),
      _ChipRow(
        children: [
          for (final purpose in SearchPurpose.all)
            ChoiceChip(
              label: Text(purpose.label),
              selected: query.purpose == purpose,
              onSelected: (_) => notifier.applyPurpose(purpose),
            ),
        ],
      ),
      _FilterLabel('ジャンル'),
      _ChipRow(
        children: [
          ChoiceChip(
            label: const Text('指定なし'),
            selected: query.category == null,
            onSelected: (_) => notifier.setCategory(null),
          ),
          for (final c in LifeEventCategories.all)
            ChoiceChip(
              label: Text('${LifeEventCategories.emojiFor(c)} $c'),
              selected: query.category == c,
              onSelected: (_) => notifier.setCategory(c),
            ),
        ],
      ),
      _FilterLabel('気持ち'),
      _ChipRow(
        children: [
          ChoiceChip(
            label: const Text('指定なし'),
            selected: query.emotionTag == null,
            onSelected: (_) => notifier.setEmotionTag(null),
          ),
          for (final tag in EmotionTag.all)
            ChoiceChip(
              label: Text('${tag.emoji} ${tag.label}'),
              selected: query.emotionTag == tag.label,
              onSelected: (_) => notifier.setEmotionTag(tag.label),
            ),
        ],
      ),
      _FilterLabel('出来事が起きた年代', help: '生年月を登録している人の記録から探します'),
      _ChipRow(
        children: [
          ChoiceChip(
            label: const Text('指定なし'),
            selected: query.decade == null,
            onSelected: (_) => notifier.setDecade(null),
          ),
          for (final d in _decades)
            ChoiceChip(
              label: Text(d == 60 ? '60代以上' : '$d代'),
              selected: query.decade == d,
              onSelected: (_) => notifier.setDecade(d),
            ),
        ],
      ),
      if (query.purpose != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              const Icon(Icons.tips_and_updates_outlined, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(query.purpose!.readingTip, style: textTheme.bodySmall)),
            ],
          ),
        ),
      const Divider(height: 24),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('さがす')),
      // 条件を変えても入力欄が作り直されないよう、1つのリストの中で結果を切り替える。
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          ...header,
          ...resultsAsync.when(
            skipLoadingOnReload: true,
            data: (events) => [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text('「${query.summary}」のライフイベント ${events.length}件', style: textTheme.bodySmall),
              ),
              if (events.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: EmptyView(
                    message: '条件に合うライフイベントが見つかりませんでした。\n条件を「指定なし」に戻してみてください。',
                    icon: Icons.search_off,
                  ),
                ),
              for (final event in events)
                LifeEventCard(
                  key: ValueKey(event.eventId),
                  event: event,
                  onTap: () => context.push('/life-event/${event.eventId}'),
                ),
            ],
            loading: () => const [LoadingView()],
            error: (e, st) => [
              ErrorView(error: e, onRetry: () => ref.invalidate(searchResultsProvider)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  final String title;
  final String? help;

  const _FilterLabel(this.title, {this.help});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: title, style: textTheme.titleSmall),
            if (help != null) TextSpan(text: '  $help', style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// 横にスクロールする選択チップの列。
class _ChipRow extends StatelessWidget {
  final List<Widget> children;

  const _ChipRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final child in children)
            Padding(padding: const EdgeInsets.only(right: 8), child: child),
        ],
      ),
    );
  }
}
