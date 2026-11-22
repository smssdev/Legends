abstract final class AppConfig {
  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  static const apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080',
  );
}
