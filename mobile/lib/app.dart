import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/settings.dart';
import 'features/health/health.dart';
import 'features/health/status_screens.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';
import 'ui/theme.dart';

/// [Sprint 15 F1] The app: the night and day looks, Arabic (right to left) and English, and — before anything — a
/// version too old for the server asks to be updated.
class GlmApp extends ConsumerWidget {
  const GlmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final update = ref.watch(updateRequiredProvider).value ?? false;
    final common = (
      theme: glmTheme(day: true),
      darkTheme: glmTheme(day: false),
      themeMode: settings.theme,
      locale: settings.locale,
      supportedLocales: L.supportedLocales,
      localizationsDelegates: const [L.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
    );
    if (update) {
      return MaterialApp(debugShowCheckedModeBanner: false, onGenerateTitle: (c) => L.of(c).appName, theme: common.theme, darkTheme: common.darkTheme,
          themeMode: common.themeMode, locale: common.locale, supportedLocales: common.supportedLocales, localizationsDelegates: common.localizationsDelegates,
          home: const UpdateRequiredScreen());
    }
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (c) => L.of(c).appName,
      theme: common.theme,
      darkTheme: common.darkTheme,
      themeMode: common.themeMode,
      locale: common.locale,
      supportedLocales: common.supportedLocales,
      localizationsDelegates: common.localizationsDelegates,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
