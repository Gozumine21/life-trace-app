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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final notifier = ref.read(searchQueryProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('さがす')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'キーワードで絞り込む（任意）',
                    hintText: '例: 受験、転職、結婚',
                    prefixIcon: Icon(Icons.search),
                  ),
                  textInputAction: TextInputAction.search,
                  onChanged: notifier.setKeyword,
                ),
                const SizedBox(height: 12),
                SegmentedButton<SearchFilterType>(
                  segments: const [
                    ButtonSegment(
                      value: SearchFilterType.category,
                      icon: Icon(Icons.category_outlined),
                      label: Text('ジャンルで'),
                    ),
                    ButtonSegment(
                      value: SearchFilterType.emotionTag,
                      icon: Icon(Icons.mood),
                      label: Text('気持ちで'),
                    ),
                  ],
                  selected: {query.filterType},
                  onSelectionChanged: (selection) {
                    final type = selection.first;
                    notifier.setFilterType(type);
                    notifier.setValue(
                      type == SearchFilterType.category
                          ? LifeEventCategories.all.first
                          : EmotionTag.all.first.label,
                    );
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (query.filterType == SearchFilterType.category
                          ? LifeEventCategories.all
                          : EmotionTag.all.map((e) => e.label).toList())
                      .map(
                        (value) => ChoiceChip(
                          label: Text(
                            query.filterType == SearchFilterType.category
                                ? '${LifeEventCategories.emojiFor(value)} $value'
                                : '${EmotionTag.emojiFor(value)} $value',
                          ),
                          selected: query.value == value,
                          onSelected: (_) => notifier.setValue(value),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: resultsAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return const EmptyView(
                    message: '条件に合うライフイベントが見つかりませんでした。\n別のジャンルや気持ちを選んでみてください。',
                    icon: Icons.search_off,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: events.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          '「${query.value}」のライフイベント ${events.length}件',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    }
                    final event = events[index - 1];
                    return LifeEventCard(
                      event: event,
                      onTap: () => context.push('/life-event/${event.eventId}'),
                    );
                  },
                );
              },
              loading: () => const LoadingView(),
              error: (e, st) => ErrorView(error: e, onRetry: () => ref.invalidate(searchResultsProvider)),
            ),
          ),
        ],
      ),
    );
  }
}
