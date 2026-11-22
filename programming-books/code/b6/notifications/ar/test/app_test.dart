import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/cafe.dart';
import 'package:bit_app/demo_push.dart';
import 'package:bit_app/push/message.dart';

const ready = PushMessage(
  PushKind.orderReady,
  orderId: '42',
  title: 'Your latte is ready',
);

void main() {
  testWidgets('رسالة في المقدمة تعرض شريطاً يفتح الطلب', (tester) async {
    final push = DemoPush();
    await tester.pumpWidget(CafeApp(push: push));
    push.foregroundMessages.add(ready);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    expect(find.text('Your latte is ready'), findsOneWidget);
    await tester.tap(find.text('اعرض'));
    await tester.pumpAndSettle();
    expect(find.text('الطلب 42'), findsOneWidget);
  });

  testWidgets('إشعار مضغوط يفتح طلبه', (tester) async {
    final push = DemoPush();
    await tester.pumpWidget(CafeApp(push: push));
    push.openedMessages.add(ready);
    await tester.pumpAndSettle();
    expect(find.text('الطلب 42'), findsOneWidget);
  });

  testWidgets('إشعار شغّل التطبيق يفتح طلبه', (tester) async {
    final push = DemoPush()..started = ready;
    await tester.pumpWidget(CafeApp(push: push));
    await tester.pumpAndSettle();
    expect(find.text('الطلب 42'), findsOneWidget);
  });
}
