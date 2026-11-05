import 'dart:async';

import 'package:app_links/app_links.dart';
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
class GlmApp extends ConsumerStatefulWidget {
  const GlmApp({super.key});

  @override
  ConsumerState<GlmApp> createState() => _GlmAppState();
}

class _GlmAppState extends ConsumerState<GlmApp> {
  StreamSubscription<Uri>? _links;

  /// [Sprint 16 F2] An invite link (gamelegendmanager.online/join/CODE) opens the app on its code, at the start or while it
  /// runs; a guest signs in first and lands on it (router.dart).
  @override
  void initState() {
    super.initState();
    final links = AppLinks();
    void open(Uri uri) {
      if (uri.pathSegments.length >= 2 && uri.pathSegments.first == 'join') ref.read(routerProvider).go('/join/${uri.pathSegments[1]}');
    }
    links.getInitialLink().then((u) => u == null ? null : open(u)).catchError((_) => null);
    _links = links.uriLinkStream.listen(open, onError: (_) {});
  }

  @override
  void dispose() {
    _links?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
