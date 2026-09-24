import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:life_trace_app/features/auth/providers/auth_providers.dart';
import 'package:life_trace_app/features/onboarding/providers/onboarding_providers.dart';
import 'package:life_trace_app/features/onboarding/screens/how_to_use_screen.dart';

void main() {
  testWidgets('使い方ページは考え方と6つの使い方を説明する', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MaterialApp(home: HowToUseScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('人生は、誰かのヒントになる'), findsOneWidget);
    for (final title in [
      '1. 自分の人生を記録する',
      '2. 自分の人生を振り返る',
      '3. 経験を分かち合う',
      '4. ほかの人の人生にふれる',
      '5. 気持ちを伝え合う',
      '6. 安心して使うために',
    ]) {
      await tester.scrollUntilVisible(find.text(title), 200);
      expect(find.text(title), findsOneWidget);
    }
    // ログイン前は、画面移動のボタンを出さない。
    expect(find.text('記録してみる'), findsNothing);
  });
}
