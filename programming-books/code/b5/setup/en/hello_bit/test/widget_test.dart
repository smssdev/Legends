import 'package:flutter_test/flutter_test.dart';
import 'package:hello_bit/main.dart';

void main() {
  testWidgets('shows the greeting', (WidgetTester tester) async {
    await tester.pumpWidget(const HelloBitApp());
    expect(find.text('Hello, hot reload!'), findsOneWidget);
  });
}
