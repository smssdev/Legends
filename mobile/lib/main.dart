import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/api/intents.dart';
import 'core/crash_reports.dart';
import 'core/device_tier.dart';
import 'core/settings.dart';
import 'ui/widgets/broken_part.dart';

/// Game Legend Manager (المدرب الأسطورة) for Android and iOS [Sprint 15]: the same game as the web, on the same API.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // [Sprint 66 F1] The errors on the players' phones, to our own server (nothing personal: core/crash_reports.dart),
  // and a calm card instead of Flutter's error box in a release.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    CrashReports.report(details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    CrashReports.report(error, stack);
    return true;
  };
  if (kReleaseMode) ErrorWidget.builder = (_) => const BrokenPart();
  unawaited(PackageInfo.fromPlatform().then((i) => CrashReports.version = i.version, onError: (_) {}));
  await initializeDateFormatting();
  // [2026-11-06] The game plays in landscape, as the owner asked: wide screens, a side rail, two columns.
  // [Sprint 74 P6] Not waited for: the first frame does not need their answer (the manifest already holds the screen
  // sideways), and each was a round trip to the platform before anything was drawn.
  unawaited(SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]));
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky));
  final preferences = await SharedPreferences.getInstance();
  Intents.load(preferences);
  // [Sprint 74 P3] The phone's tier (its endless motion off on a weak one), watched from the first frame.
  DeviceTiers.start(preferences);
  runApp(ProviderScope(overrides: [preferencesProvider.overrideWithValue(preferences)], child: const GlmApp()));
}
