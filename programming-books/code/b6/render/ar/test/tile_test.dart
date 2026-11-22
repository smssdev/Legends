import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('ListTile عناصر كثيرة وكائنات رسم قليلة', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: ListTile(
            leading: Icon(Icons.star),
            title: Text('Bit'),
            trailing: Icon(Icons.chevron_right),
          ),
        ),
      ),
    );
    final tile = tester.element(find.byType(ListTile));
    var elements = 0;
    final renderObjects = <String>[];
    void walk(Element e) {
      elements++;
      if (e is RenderObjectElement) {
        renderObjects.add('${e.renderObject.runtimeType}');
      }
      e.visitChildren(walk);
    }

    walk(tile);
    debugPrint('$elements elements, ${renderObjects.length} render objects:');
    debugPrint(renderObjects.join(', '));
    expect(renderObjects.length, lessThan(elements));
  });
}
