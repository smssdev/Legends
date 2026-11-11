import 'package:flutter/foundation.dart';

/// [Sprint 15 F1] Where the app talks to: the game's API (README section 8). A build for another server passes
/// `--dart-define=API_URL=https://…/api/v1`; the site is the same address without /api/v1.
abstract final class AppConfig {
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'https://gamelegendmanager.online/api/v1');
  static String get siteUrl => apiUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');

  /// [Sprint 53 F1] Reverb's app key (public by design, as in the web's build: web/src/lib/echo.ts); another server's
  /// build passes `--dart-define=REVERB_KEY=…`.
  static const reverbKey = String.fromEnvironment('REVERB_KEY', defaultValue: 'legends-dev-key');

  /// The name a token is made for (the account's devices list shows it): the phone's system, so an iPhone is not
  /// listed as Android.
  static String get deviceName => switch (defaultTargetPlatform) {
        TargetPlatform.iOS => 'GLM iOS',
        TargetPlatform.android => 'GLM Android',
        TargetPlatform.macOS => 'GLM macOS',
        TargetPlatform.windows => 'GLM Windows',
        TargetPlatform.linux => 'GLM Linux',
        TargetPlatform.fuchsia => 'GLM',
      };
}
