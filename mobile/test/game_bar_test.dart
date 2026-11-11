import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/features/leagues/shell.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/theme.dart';

/// [Sprint 51 F1] The top bar's title is in the game's font: AppBar replaces the theme's title style rather than merging
/// it, and without a family the title fell back to the system's (boxes in the screenshots).
void main() {
  testWidgets("the top bar's title is in the game's font", (t) async {
    await t.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: glmTheme(day: false),
        locale: const Locale('ar'),
        supportedLocales: L.supportedLocales,
        localizationsDelegates: const [L.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        home: const Scaffold(appBar: GameBar(title: Text('السوق'))),
      ),
    ));
    final style = DefaultTextStyle.of(t.element(find.text('السوق'))).style;
    expect(style.fontFamily, GlmFonts.body);
    expect(style.fontWeight, FontWeight.w800);
  });
}
