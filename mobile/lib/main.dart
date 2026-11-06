import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/settings.dart';

/// Game Legend Manager (المدرب الأسطورة) for Android and iOS [Sprint 15]: the same game as the web, on the same API.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  // [2026-11-06] The game plays in landscape, as the owner asked: wide screens, a side rail, two columns.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final preferences = await SharedPreferences.getInstance();
  runApp(ProviderScope(overrides: [preferencesProvider.overrideWithValue(preferences)], child: const GlmApp()));
}
