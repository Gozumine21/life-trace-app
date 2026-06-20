import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../models/life_event.dart';

enum SearchFilterType { category, emotionTag }

class SearchQueryState {
  final SearchFilterType filterType;
  final String value;
  final String keyword;

  const SearchQueryState({
    required this.filterType,
    required this.value,
    this.keyword = '',
  });

  SearchQueryState copyWith({
    SearchFilterType? filterType,
    String? value,
    String? keyword,
  }) {
    return SearchQueryState(
      filterType: filterType ?? this.filterType,
      value: value ?? this.value,
      keyword: keyword ?? this.keyword,
    );
  }
}

class SearchQueryNotifier extends Notifier<SearchQueryState> {
  @override
  SearchQueryState build() {
    return const SearchQueryState(
      filterType: SearchFilterType.category,
      value: '学業',
    );
  }

  void setFilterType(SearchFilterType type) {
    state = state.copyWith(filterType: type);
  }

  void setValue(String value) {
    state = state.copyWith(value: value);
  }

  void setKeyword(String keyword) {
    state = state.copyWith(keyword: keyword);
  }
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, SearchQueryState>(
  SearchQueryNotifier.new,
);

final searchResultsProvider = StreamProvider<List<LifeEvent>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final service = ref.watch(firestoreServiceProvider);
  final stream = query.filterType == SearchFilterType.category
      ? service.watchByCategory(query.value)
      : service.watchByEmotionTag(query.value);
  if (query.keyword.trim().isEmpty) return stream;
  final keyword = query.keyword.trim();
  return stream.map(
    (events) => events
        .where(
          (e) =>
              e.title.contains(keyword) || e.body.contains(keyword),
        )
        .toList(),
  );
});
