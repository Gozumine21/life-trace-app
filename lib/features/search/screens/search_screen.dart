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
      appBar: AppBar(title: const Text('検索')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'キーワード（タイトル・本文）',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: notifier.setKeyword,
                ),
                const SizedBox(height: 12),
                SegmentedButton<SearchFilterType>(
                  segments: const [
                    ButtonSegment(value: SearchFilterType.category, label: Text('カテゴリ')),
                    ButtonSegment(value: SearchFilterType.emotionTag, label: Text('感情タグ')),
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
                          label: Text(value),
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
                  return const EmptyView(message: '該当するライフイベントが見つかりませんでした');
                }
                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return LifeEventCard(
                      event: event,
                      onTap: () => context.push('/life-event/${event.eventId}'),
                    );
                  },
                );
              },
              loading: () => const LoadingView(),
              error: (e, st) => ErrorView(error: e),
            ),
          ),
        ],
      ),
    );
  }
}
