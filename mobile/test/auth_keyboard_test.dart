import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/settings.dart';
import 'package:glm/core/sounds.dart';
import 'package:glm/features/auth/ui/login_screen.dart';
import 'package:glm/features/auth/ui/register_screen.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [X98] Sign-in and sign-up with the keyboard coming up and going, as on a phone (the screenshots only drew the
/// keyboard already up): the field tapped keeps its focus and its text when the pitch beside the form goes, and the
/// form is there again, with what was typed, when the keyboard closes.
void main() {
  Future<void> open(WidgetTester t, Widget screen) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    GameSounds.enabled = false;
    t.view.physicalSize = const Size(800, 360) * 2;
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      ProviderScope(
        overrides: [preferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: glmTheme(day: true),
          locale: const Locale('ar'),
          supportedLocales: L.supportedLocales,
          localizationsDelegates: const [
            L.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: screen,
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 600));
  }

  for (final (name, screen, greeting, fields) in [
    ('sign-in', const LoginScreen() as Widget, 'أهلاً بعودتك', 2),
    ('sign-up', const RegisterScreen(), 'حسابك الجديد', 4),
  ]) {
    testWidgets('$name: the keyboard comes up and the field keeps its focus and its text', (t) async {
      await open(t, screen);
      expect(find.text(greeting), findsOneWidget);
      expect(find.byType(EditableText), findsNWidgets(fields));
      final field = find.byType(EditableText).first;
      await t.tap(field);
      await t.pump();
      // The keyboard slides up: the phone reports its height a frame at a time.
      for (final h in [60.0, 140.0, 200.0]) {
        t.view.viewInsets = FakeViewPadding(bottom: h * 2);
        await t.pump(const Duration(milliseconds: 50));
      }
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text(greeting), findsNothing, reason: 'the pitch beside the form goes while typing');
      expect(find.byType(EditableText), findsNWidgets(fields));
      expect(t.widget<EditableText>(field).focusNode.hasFocus, isTrue, reason: 'the field tapped lost its focus');
      await t.enterText(field, 'hamza');
      await t.pump();
      expect(t.getRect(field).bottom, lessThanOrEqualTo(360 - 200), reason: 'the field is under the keyboard');
      // And down again: the form whole, with what was typed.
      t.view.viewInsets = FakeViewPadding.zero;
      await t.pump(const Duration(milliseconds: 400));
      expect(t.takeException(), isNull);
      expect(find.text(greeting), findsOneWidget);
      expect(find.text('hamza'), findsOneWidget);
      expect(t.widget<EditableText>(find.byType(EditableText).first).controller.text, 'hamza');
      final box = t.getRect(find.byType(EditableText).first);
      expect(box.width > 100 && box.left >= 0 && box.right <= 800, isTrue, reason: 'the form is on the screen ($box)');
    });
  }
}
