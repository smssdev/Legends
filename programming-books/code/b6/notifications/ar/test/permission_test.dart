import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/cafe.dart';
import 'package:bit_app/demo_push.dart';
import 'package:bit_app/push/push_source.dart';

void main() {
  testWidgets('بطاقة الإذن تظهر بعد أول طلب، ومرة واحدة', (tester) async {
    final push = DemoPush(answer: PermissionState.denied);
    await tester.pumpWidget(CafeApp(push: push));
    await tester.pumpAndSettle();
    expect(find.byType(PermissionCard), findsNothing);

    await tester.tap(find.text('اطلب لاتيه'));
    await tester.pumpAndSettle();
    expect(find.byType(PermissionCard), findsOneWidget);

    await tester.tap(find.text('فعّل'));
    await tester.pumpAndSettle();
    expect(push.requests, 1);
    expect(find.byType(PermissionCard), findsNothing);
    expect(
      find.text('الإشعارات مطفأة. يمكنك تفعيلها من الإعدادات.'),
      findsOneWidget,
    );
  });
}
