import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:bit_app/bilingual_app.dart';

void main() {
  testWidgets('choosing Arabic translates the app, turns it, and remembers', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final choice = LanguageChoice(SharedPreferencesAsync());
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: choice, child: const CafeApp()),
    );
    // The test's "phone" speaks English.
    expect(find.text('Bit Café'), findsOneWidget);

    await tester.tap(find.byTooltip('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();

    expect(find.text('مقهى بِت'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('مقهى بِت'))),
      TextDirection.rtl,
    );
    expect(await SharedPreferencesAsync().getString('language'), 'ar');
  });
}
