import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:bit_app/projects_settings.dart';

void main() {
  testWidgets('الإعداد يغيّر التطبيق كله', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => Settings(),
        child: const SettingsApp(),
      ),
    );
    final app = find.byType(MaterialApp);
    expect(tester.widget<MaterialApp>(app).themeMode, ThemeMode.light);

    await tester.tap(find.text('الوضع الداكن'));
    await tester.pumpAndSettle();
    expect(tester.widget<MaterialApp>(app).themeMode, ThemeMode.dark);
  });
}
