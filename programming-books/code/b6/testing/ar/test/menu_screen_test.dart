import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/data/menu.dart';
import 'package:bit_app/ui/menu_screen.dart';

// بديل مزيّف: سلوك حقيقي بلا شبكة. والاختبار يقرر متى تصل القائمة.
class FakeMenu implements MenuRepository {
  final arrives = Completer<List<Drink>>();

  @override
  Future<List<Drink>> menu() => arrives.future;
}

const drinks = [Drink('latte', 'Latte', 45), Drink('cake', 'Cherry cake', 55)];

Widget screen(MenuRepository repository) => MaterialApp(
  // العاشرة صباحاً في يوم عمل: لا ساعة سعادة، فالمجموع معروف مسبقاً.
  home: MenuScreen(
    repository: repository,
    now: () => DateTime(2026, 11, 23, 10),
  ),
);

void main() {
  testWidgets('يعرض مؤشراً ثم القائمة', (tester) async {
    final fake = FakeMenu();
    await tester.pumpWidget(screen(fake));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    fake.arrives.complete(drinks);
    await tester.pump();
    expect(find.text('Latte'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('الضغط على مشروب يضيفه إلى المجموع', (tester) async {
    final fake = FakeMenu()..arrives.complete(drinks);
    await tester.pumpWidget(screen(fake));
    await tester.pump();
    await tester.tap(find.text('Latte'));
    await tester.tap(find.text('Latte'));
    await tester.tap(find.text('Cherry cake'));
    await tester.pump();
    expect(find.textContaining(': 145 '), findsOneWidget);
  });
}
