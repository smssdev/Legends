import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('الأشجار الثلاث لشاشة صغيرة', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Padding(padding: EdgeInsets.all(8), child: Text('Bit')),
        ),
      ),
    );
    // كل عنصر، من Directionality إلى الأسفل، مع الـ Widget وكائن الرسم الخاصين به.
    final root = tester.element(find.byType(Directionality));
    void show(Element e, int depth) {
      // RenderObjectElement وحده يملك كائن رسم؛ والباقي يبني Widgets فقط.
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
