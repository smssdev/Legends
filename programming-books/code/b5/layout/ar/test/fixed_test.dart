import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('الصف نفسه، مع Flexible', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 300,
          child: Row(
            children: [
              Icon(Icons.local_cafe),
              Flexible(
                child: Text(
                  'اسم طويل جداً لمشروب لا يتسع له سطر واحد في الشاشة',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  });
}
