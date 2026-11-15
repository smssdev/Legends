import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/crash_reports.dart';
import 'core/api/api_error.dart';
import 'core/settings.dart';
import 'core/sounds.dart';
import 'features/assistant/assistant.dart';
import 'features/auth/auth_controller.dart';
import 'features/health/health.dart';
import 'features/health/status_screens.dart';
import 'features/inbox/inbox_data.dart';
import 'features/notifications/push.dart';
import 'l10n/app_localizations.dart';
import 'features/health/offline_bar.dart';
import 'router.dart';
import 'ui/theme.dart';
import 'ui/size_class.dart';

/// [Sprint 65 F2] The largest system text size the screens follow (M-A02): tested at it, held there beyond it.
const maxTextScale = 1.3;

/// [Sprint 15 F1] The app: the night and day looks, Arabic (right to left) and English, and — before anything — a
/// version too old for the server asks to be updated.

class GlmApp extends ConsumerStatefulWidget {
  const GlmApp({super.key});

  @override
  ConsumerState<GlmApp> createState() => _GlmAppState();
}

class _GlmAppState extends ConsumerState<GlmApp> {
  StreamSubscription<Uri>? _links;
  StreamSubscription<String>? _taps;
  StreamSubscription<void>? _arrivals;

  /// [Sprint 16 F2] An invite link (gamelegendmanager.online/join/CODE) opens the app on its code, at the start or while it
  /// runs; a guest signs in first and lands on it (router.dart).
  @override
  void initState() {
    super.initState();
    final links = AppLinks();
    void open(Uri uri) {
      final seg = uri.pathSegments;
      if (seg.length >= 2 && seg.first == 'join') ref.read(routerProvider).go('/join/${seg[1]}');
      // [Sprint 18 G] A group's invite link.
      if (seg.length >= 3 && seg.first == 'groups' && seg[1] == 'join') ref.read(routerProvider).push('/groups/join/${seg[2]}');
    }

    links.getInitialLink().then((u) => u == null ? null : open(u)).catchError((_) => null);
    _links = links.uriLinkStream.listen(open, onError: (_) {});

    // [Sprint 66 F1] The screen on show, for a crash report (its path only).
    final shown = ref.read(routerProvider).routerDelegate;
    shown.addListener(() => CrashReports.path = shown.currentConfiguration.uri.path);

    // [Sprint 19 F1] Pushes: started for a signed-in coach; a tap opens its screen, an arrival refreshes the inbox count.
    final push = ref.read(pushProvider);
    _taps = push.taps.listen((route) {
      final router = ref.read(routerProvider);
      if (knownRoute(router, route)) unawaited(router.push(route));
    });
    _arrivals = push.arrivals.listen((_) => ref.invalidate(unreadProvider));
    ref.listenManual(authProvider, (_, next) {
      if (next.value != null) push.start();
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _links?.cancel();
    _taps?.cancel();
    _arrivals?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    GameSounds.enabled = settings.sounds;
    GameSounds.ui = settings.soundUi;
    GameSounds.touch = settings.touch;
    GameSounds.stadium = settings.soundStadium;
    final update = ref.watch(updateRequiredProvider).value ?? false;
    ApiError.locale = settings.locale;
    // [Sprint 59 F12] One MaterialApp: an update the server requires replaces the routed screens, not the app.
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (c) => L.of(c).appName,
      theme: glmTheme(day: true),
      darkTheme: glmTheme(day: false),
      themeMode: settings.theme,
      locale: settings.locale,
      supportedLocales: L.supportedLocales,
      localizationsDelegates: const [
        L.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
      // [Sprint 18 H] The assistant coach over every screen.
      // [Sprint 61 F9] The one «لا اتصال» bar above the frame.
      // [Sprint 65 F2] The system's text size up to 1.3× (the screens are tested there, test/shots); beyond it held at 1.3.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: maxTextScale,
        // [Sprint 72 R7] A tablet: everything drawn larger (ui/size_class.dart).
        child: GlmScale(
          child: update
              ? const UpdateRequiredScreen()
              : OfflineBar(
                  child: AssistantOverlay(router: ref.watch(routerProvider), child: child ?? const SizedBox()),
                ),
        ),
      ),
    );
  }
}
