import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:life_trace_app/core/utils/constants.dart';
import 'package:life_trace_app/core/utils/life_age.dart';
import 'package:life_trace_app/core/utils/privacy_check.dart';
import 'package:life_trace_app/features/emotion_graph/screens/emotion_graph_screen.dart';
import 'package:life_trace_app/features/life_event_form/screens/life_event_form_screen.dart';
import 'package:life_trace_app/models/life_event.dart';

LifeEvent _event(
  String id, {
  int score = 0,
  EventVisibility visibility = EventVisibility.public,
  String authorId = 'author',
}) {
  final now = DateTime(2026, 1, 1);
  return LifeEvent(
    eventId: id,
    authorId: authorId,
    title: id,
    body: '',
    occurredYearMonth: '2020-01',
    category: '仕事',
    emotionTag: '普通',
    emotionScore: score,
    isTurningPoint: false,
    imageUrls: const [],
    visibility: visibility,
    likeCount: 0,
    commentCount: 0,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('LifeEvent.isVisibleTo', () {
    test('非公開の記録は本人にしか見えない', () {
      final e = _event('a', visibility: EventVisibility.private);
      expect(e.isVisibleTo('author', viewerFollowsAuthor: false), isTrue);
      expect(e.isVisibleTo('other', viewerFollowsAuthor: true), isFalse);
      expect(e.isVisibleTo(null, viewerFollowsAuthor: false), isFalse);
    });

    test('フォロワー限定はフォローしている人だけに見える', () {
      final e = _event('a', visibility: EventVisibility.followers);
      expect(e.isVisibleTo('other', viewerFollowsAuthor: true), isTrue);
      expect(e.isVisibleTo('other', viewerFollowsAuthor: false), isFalse);
    });

    test('応答記録の元IDは保存・読み込みで保たれる', () {
      final map = LifeEvent(
        eventId: 'r',
        authorId: 'x',
        title: 't',
        body: 'b',
        occurredYearMonth: '2020-01',
        category: '仕事',
        emotionTag: '普通',
        emotionScore: 0,
        isTurningPoint: false,
        imageUrls: const [],
        visibility: EventVisibility.public,
        likeCount: 0,
        commentCount: 0,
        respondsToEventId: 'orig',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ).toMap();
      expect(LifeEvent.fromMap('r', map).respondsToEventId, 'orig');
      expect(_event('a').toMap().containsKey('respondsToEventId'), isFalse);
    });
  });

  group('PrivacyCheck', () {
    test('電話番号・メールアドレス・番地を見つける', () {
      expect(PrivacyCheck.findConcerns('連絡は090-1234-5678まで'), ['電話番号']);
      expect(PrivacyCheck.findConcerns('taro@example.com に送った'), ['メールアドレス']);
      expect(PrivacyCheck.findConcerns('3丁目の角の家'), ['住所の番地']);
      expect(PrivacyCheck.findConcerns('〒100-0001 の近く'), ['郵便番号']);
    });

    test('年月や順位などの普通の数字は注意しない', () {
      expect(PrivacyCheck.findConcerns('2015年4月に入社し、2020-09に転職。1番になった'), isEmpty);
    });
  });

  group('LifeAge', () {
    test('生年月から出来事のときの年齢と年代を出す', () {
      expect(LifeAge.ageAt(birthYearMonth: '1990-04', occurredYearMonth: '2018-03'), 27);
      expect(LifeAge.ageAt(birthYearMonth: '1990-04', occurredYearMonth: '2018-04'), 28);
      expect(LifeAge.decadeAt(birthYearMonth: '1990-04', occurredYearMonth: '2018-04'), 20);
      expect(LifeAge.label(birthYearMonth: null, occurredYearMonth: '2018-04'), isNull);
      expect(LifeAge.parseYearMonth('1990-13'), isNull);
    });

    test('誕生月と12月はふり返りの時期', () {
      expect(LifeAge.isReviewMonth(birthYearMonth: '1990-04', now: DateTime(2026, 4, 2)), isTrue);
      expect(LifeAge.isReviewMonth(birthYearMonth: '1990-04', now: DateTime(2026, 12, 2)), isTrue);
      expect(LifeAge.isReviewMonth(birthYearMonth: '1990-04', now: DateTime(2026, 9, 2)), isFalse);
    });
  });

  test('谷からの回復は、続いた谷の最後と、次に上向いた出来事を組にする', () {
    final events = [
      _event('valley1', score: -4),
      _event('valley2', score: -5),
      _event('flat', score: 0),
      _event('peak', score: 3),
      _event('valley3', score: -3),
    ];
    final recoveries = findRecoveries(events);
    expect(recoveries.map((r) => '${r.$1.eventId}->${r.$2.eventId}'), ['valley2->peak']);
  });

  testWidgets('「5つの問い」ボタンで本文に書き方のヒントが入り、既定は非公開', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: LifeEventFormScreen())));

    await tester.tap(find.text('書き方のヒント（5つの問い）を入れる'));
    await tester.pump();
    final body = tester.widgetList<EditableText>(find.byType(EditableText)).elementAt(1);
    expect(body.controller.text, WritingGuide.bodyTemplate);

    final radio = tester.widget<RadioGroup<String>>(find.byType(RadioGroup<String>));
    expect(radio.groupValue, VisibilityOption.private);
    expect(find.text('全体公開の前に確かめましょう'), findsNothing);
  });
}
