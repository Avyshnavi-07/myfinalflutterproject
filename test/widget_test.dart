import 'package:flutter_test/flutter_test.dart';
import 'package:flutterthree/main.dart';

void main() {
  testWidgets('Basic app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('My To-Do List'), findsOneWidget);
  });
}