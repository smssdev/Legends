import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('a long name in a row', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 300,
          child: Row(
            children: [
              Icon(Icons.local_cafe),
              Text(
                'A very long name for a drink that does not fit on one line',
              ),
            ],
          ),
        ),
      ),
    );
  });
}
