import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_routes.dart';

void main() {
  testWidgets('المشروب غير المعروف يعرض صفحة «غير موجود»', (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router('/drinks/99')),
    );
    await tester.pumpAndSettle();
    expect(find.text('الصفحة غير موجودة'), findsOneWidget);

    await tester.tap(find.text('العودة إلى القائمة'));
    await tester.pumpAndSettle();
    expect(find.text('لاتيه'), findsOneWidget);
  });
}
