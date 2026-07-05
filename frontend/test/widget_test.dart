import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:myapp/app.dart';

void main() {
  testWidgets('Home screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CtuApp()));

    expect(find.text('CTU Student\nService'), findsOneWidget);
    expect(find.text('Bắt đầu hỏi'), findsOneWidget);
  });
}
