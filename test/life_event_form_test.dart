import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:life_trace_app/features/life_event_form/screens/life_event_form_screen.dart';

void main() {
  Future<void> pumpForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LifeEventFormScreen())),
    );
  }

  testWidgets('新規作成では今月が初期値になり、ダイアログで年月を変えられる', (tester) async {
    await pumpForm(tester);
    final now = DateTime.now();
    expect(find.text('${now.year}年 ${now.month}月'), findsOneWidget);

    await tester.tap(find.text('${now.year}年 ${now.month}月'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('前の年'));
    await tester.pump();
    await tester.tap(find.text('3月'));
    await tester.pump();
    await tester.tap(find.text('決定'));
    await tester.pumpAndSettle();

    expect(find.text('${now.year - 1}年 3月'), findsOneWidget);
  });

  testWidgets('未入力のまま保存すると、分かりやすいエラーが出る', (tester) async {
    await pumpForm(tester);
    await tester.tap(find.text('この内容で記録する'));
    await tester.pumpAndSettle();

    expect(find.text('タイトルを入力してください'), findsOneWidget);
    expect(find.text('本文を入力してください'), findsOneWidget);
    expect(find.textContaining('未入力の項目があります'), findsOneWidget);
  });

  testWidgets('感情とジャンルは絵文字つきのチップで選べる', (tester) async {
    await pumpForm(tester);
    expect(find.text('😊 嬉しい'), findsOneWidget);
    expect(find.text('💼 仕事'), findsOneWidget);

    await tester.tap(find.text('😊 嬉しい'));
    await tester.pump();
    final chip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '😊 嬉しい'));
    expect(chip.selected, isTrue);
  });
}
