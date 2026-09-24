import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/utils/life_age.dart';
import '../../../models/life_event.dart';
import '../../../models/user_profile.dart';
import '../../moderation/providers/moderation_providers.dart';

/// 今の状況から探すための入口（活用マニュアル第6章）。
class SearchPurpose {
  final String label;
  final String? category;
  final String? emotionTag;

  /// 読むときに注目するとよいところ。
  final String readingTip;

  const SearchPurpose(this.label, {this.category, this.emotionTag, required this.readingTip});

  static const all = [
    SearchPurpose('進路や転職に迷っている', category: '仕事', readingTip: '選んだ理由と、その後の気持ちの変化に注目して読みましょう'),
    SearchPurpose('先が見えず不安', emotionTag: '不安', readingTip: '同じ不安をどう過ごしたかに注目して読みましょう'),
    SearchPurpose('失敗から立ち直りたい', category: '挫折', readingTip: 'その人のページで、挫折の次の記録も読んでみましょう'),
    SearchPurpose('新しいことを始めたい', category: '挑戦', readingTip: '始める前に何を準備したかに注目して読みましょう'),
    SearchPurpose('環境が変わる', category: '転居', readingTip: '慣れるまでの期間と工夫に注目して読みましょう'),
    SearchPurpose('元気がほしい', emotionTag: '最高に嬉しい', readingTip: 'そこに至るまでの道のりにも目を向けてみましょう'),
  ];
}

class SearchQueryState {
  /// null は「指定なし」。
  final String? category;
  final String? emotionTag;

  /// 出来事が起きたときの年代（10代なら 10）。
  final int? decade;
  final String keyword;
  final SearchPurpose? purpose;

  const SearchQueryState({
    this.category,
    this.emotionTag,
    this.decade,
    this.keyword = '',
    this.purpose,
  });

  /// 検索結果の見出しに使う、条件の説明。
  String get summary {
    final parts = [
      ?category,
      ?emotionTag,
      if (decade != null) '$decade代',
    ];
    return parts.isEmpty ? '新着' : parts.join('・');
  }
}

class SearchQueryNotifier extends Notifier<SearchQueryState> {
  @override
  SearchQueryState build() => const SearchQueryState(category: '学業');

  void setCategory(String? category) => state = SearchQueryState(
        category: category,
        emotionTag: state.emotionTag,
        decade: state.decade,
        keyword: state.keyword,
      );

  void setEmotionTag(String? emotionTag) => state = SearchQueryState(
        category: state.category,
        emotionTag: emotionTag,
        decade: state.decade,
        keyword: state.keyword,
      );

  void setDecade(int? decade) => state = SearchQueryState(
        category: state.category,
        emotionTag: state.emotionTag,
        decade: decade,
        keyword: state.keyword,
      );

  void setKeyword(String keyword) => state = SearchQueryState(
        category: state.category,
        emotionTag: state.emotionTag,
        decade: state.decade,
        keyword: keyword,
        purpose: state.purpose,
      );

  void applyPurpose(SearchPurpose purpose) => state = SearchQueryState(
        category: purpose.category,
        emotionTag: purpose.emotionTag,
        keyword: state.keyword,
        purpose: purpose,
      );
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, SearchQueryState>(
  SearchQueryNotifier.new,
);

final searchResultsProvider = StreamProvider<List<LifeEvent>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final service = ref.watch(firestoreServiceProvider);
  final blockedIds = ref.watch(blockedUserIdsProvider).asData?.value ?? const [];

  // Firestore には1つの条件だけで問い合わせ、残りの条件は手元で絞り込む。
  final Stream<List<LifeEvent>> stream;
  if (query.category != null) {
    stream = service.watchByCategory(query.category!);
  } else if (query.emotionTag != null) {
    stream = service.watchByEmotionTag(query.emotionTag!);
  } else {
    stream = service.watchPublicFeed(limit: 100);
  }

  // 年代の絞り込みには投稿者の生年月が必要なので、検索のあいだだけ覚えておく。
  final profiles = <String, UserProfile?>{};
  final keyword = query.keyword.trim();
  return stream.asyncMap((events) async {
    final filtered = events.where((e) {
      if (blockedIds.contains(e.authorId)) return false;
      if (query.emotionTag != null && e.emotionTag != query.emotionTag) return false;
      if (keyword.isEmpty) return true;
      return e.title.contains(keyword) || e.body.contains(keyword);
    }).toList();
    if (query.decade == null) return filtered;

    for (final authorId in filtered.map((e) => e.authorId).toSet()) {
      if (!profiles.containsKey(authorId)) {
        profiles[authorId] = await service.getUserProfile(authorId);
      }
    }
    return filtered
        .where((e) {
          final decade = LifeAge.decadeAt(
            birthYearMonth: profiles[e.authorId]?.birthYearMonth,
            occurredYearMonth: e.occurredYearMonth,
          );
          // 60代以上はまとめて扱う。
          return decade != null && (decade >= 60 ? 60 : decade) == query.decade;
        })
        .toList();
  });
});
