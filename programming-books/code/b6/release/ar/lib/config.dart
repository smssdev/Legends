// تُقرَّر حين يُبنى التطبيق، من ملف لكل بيئة: لا شيء هنا سرّي.
abstract final class AppConfig {
  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  static const apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080',
  );
  static const showDebug = bool.fromEnvironment(
    'SHOW_DEBUG',
    defaultValue: true,
  );

  static bool get isProduction => flavor == 'prod';
}
