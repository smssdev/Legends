import 'package:flutter_test/flutter_test.dart';
import 'package:hello_bit/main.dart';

void main() {
  testWidgets('يعرض التحية', (WidgetTester tester) async {
    await tester.pumpWidget(const HelloBitApp());
    expect(find.text('مرحباً بالتحديث الفوري!'), findsOneWidget);
  });
}
