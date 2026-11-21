import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('the same row, with Flexible', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 300,
          child: Row(
            children: [
              Icon(Icons.local_cafe),
              Flexible(
                child: Text(
                  'A very long name for a drink that does not fit on one line',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  });
}
