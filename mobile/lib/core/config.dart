/// [Sprint 15 F1] Where the app talks to: the game's API (README section 8). A build for another server passes
/// `--dart-define=API_URL=https://…/api/v1`; the site is the same address without /api/v1.
abstract final class AppConfig {
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'https://gamelegendmanager.online/api/v1');
  static String get siteUrl => apiUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');

  /// The name a token is made for (the account's devices list shows it).
  static const deviceName = 'GLM Android';
}
