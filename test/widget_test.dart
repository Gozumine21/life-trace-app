import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:life_trace_app/core/utils/constants.dart';
import 'package:life_trace_app/features/notifications/screens/notifications_screen.dart';
import 'package:life_trace_app/features/onboarding/providers/onboarding_providers.dart';
import 'package:life_trace_app/features/onboarding/screens/onboarding_screen.dart';
import 'package:life_trace_app/widgets/common/empty_view.dart';

void main() {
  group('OnboardingScreen', () {
    late SharedPreferences prefs;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
    });

    tearDown(() => container.dispose());

    Future<void> pumpOnboarding(WidgetTester tester) {
      return tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );
    }

    testWidgets('「次へ」で最後まで進み「はじめる」で完了が保存される', (tester) async {
      await pumpOnboarding(tester);
      expect(find.text('LifeTraceへようこそ'), findsOneWidget);
      expect(container.read(onboardingCompletedProvider), isFalse);

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('次へ'));
        await tester.pumpAndSettle();
      }
      expect(find.text('誰かの人生を追体験する'), findsOneWidget);

      await tester.tap(find.text('はじめる'));
      await tester.pumpAndSettle();
      expect(container.read(onboardingCompletedProvider), isTrue);
      expect(prefs.getBool('onboarding_completed_v1'), isTrue);
    });

    testWidgets('「スキップ」でもすぐに完了できる', (tester) async {
      await pumpOnboarding(tester);
      await tester.tap(find.text('スキップ'));
      await tester.pumpAndSettle();
      expect(container.read(onboardingCompletedProvider), isTrue);
    });
  });

  testWidgets('EmptyView は次の行動のボタンを表示する', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyView(
            message: 'まだありません',
            actionLabel: '記録する',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('記録する'));
    expect(tapped, isTrue);
  });

  group('constants', () {
    test('感情タグには絵文字とスコアがある', () {
      expect(EmotionTag.emojiFor('嬉しい'), '😊');
      expect(EmotionTag.scoreFor('絶望'), -5);
      expect(EmotionTag.scoreFor('存在しないタグ'), 0);
    });

    test('すべてのカテゴリに絵文字がある', () {
      for (final c in LifeEventCategories.all) {
        expect(LifeEventCategories.emojis.containsKey(c), isTrue, reason: c);
      }
    });

    test('公開範囲ごとに説明文がある', () {
      for (final v in VisibilityOption.all) {
        expect(VisibilityOption.descriptionFor(v), isNotEmpty);
      }
    });
  });

  test('relativeTimeLabel は経過時間を分かりやすく表す', () {
    final now = DateTime(2026, 9, 24, 12);
    expect(relativeTimeLabel(now, now: now), 'たった今');
    expect(relativeTimeLabel(now.subtract(const Duration(minutes: 5)), now: now), '5分前');
    expect(relativeTimeLabel(now.subtract(const Duration(hours: 3)), now: now), '3時間前');
    expect(relativeTimeLabel(now.subtract(const Duration(days: 2)), now: now), '2日前');
    expect(relativeTimeLabel(DateTime(2026, 1, 5), now: now), '2026/01/05');
  });
}
