import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('the three trees of a small screen', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Padding(padding: EdgeInsets.all(8), child: Text('Bit')),
        ),
      ),
    );
    // Every element, from the Directionality down, with its widget and its render object.
    final root = tester.element(find.byType(Directionality));
    void show(Element e, int depth) {
      // Only a RenderObjectElement owns a render object; the others only build widgets.
      final ro = e is RenderObjectElement
          ? '${e.renderObject.runtimeType}'
          : '-';
      debugPrint(
        '${'  ' * depth}${e.widget.runtimeType} | ${e.runtimeType} | $ro',
      );
      e.visitChildren((child) => show(child, depth + 1));
    }

    show(root, 0);
  });
}
