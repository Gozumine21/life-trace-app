import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:life_trace_app/app.dart';

void main() {
  testWidgets('Home placeholder screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LifeTraceApp()));

    expect(find.text('LifeTrace'), findsOneWidget);
  });
}
