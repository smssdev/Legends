import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/features/health/intro_screen.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/theme.dart';

void main() {
  testWidgets('the opening: done at once when the motion is off (as in the tests), then the crest waits', (t) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: glmTheme(day: false), locale: const Locale('ar'), supportedLocales: L.supportedLocales, localizationsDelegates: L.localizationsDelegates,
          home: const IntroScreen()),
    ));
    await t.pump();
    expect(container.read(introDoneProvider), isTrue);
    expect(find.text('المدرب الأسطورة'), findsOneWidget);
  });
}
