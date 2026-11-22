import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/menu_careful.dart';

// What a screen reader visits, in order, as it moves forward through the screen.
List<String> heard(WidgetTester tester) {
  final said = <String>[];
  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    final name = data.label.isNotEmpty ? data.label : data.tooltip;
    if (name.isNotEmpty) {
      said.add(name.split('\n').first);
    }
    node
        .debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder)
        .forEach(visit);
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return said;
}

Future<void> firstRow(WidgetTester tester, String how, Widget app) async {
  await tester.pumpWidget(app);
  debugPrint(
    '${how.padRight(22)}${heard(tester).skip(1).take(3).join('  ->  ')}',
  );
}

void main() {
  testWidgets('the reading order of a right-to-left menu', (tester) async {
    final semantics = tester.ensureSemantics();
    await firstRow(
      tester,
      'Directionality only:',
      MaterialApp(
        key: const ValueKey(1),
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: const CarefulMenu(),
      ),
    );
    await firstRow(
      tester,
      'Arabic locale:',
      const MaterialApp(
        key: ValueKey(2),
        locale: Locale('ar'),
        supportedLocales: [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: CarefulMenu(),
      ),
    );
    semantics.dispose();
  });
}
