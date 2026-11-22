import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

// Keychain on iOS, keys from the Android Keystore; on the web, see section 14.2.
class DeviceSecureStore implements SecureStore {
  final _storage = const FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class TokenStore {
  TokenStore(this.secure, {DateTime Function()? now})
    : now = now ?? DateTime.now;

  final SecureStore secure;
  final DateTime Function() now;
  // The short-lived token lives in memory only: it dies with the app.
  String? _access;
  DateTime? _expires;

  Future<void> signedIn({
    required String access,
    required Duration lifetime,
    required String refresh,
  }) async {
    _access = access;
    _expires = now().add(lifetime);
    await secure.write('refresh', refresh);
  }

  String? get access =>
      _expires != null && now().isBefore(_expires!) ? _access : null;

  Future<String?> refreshToken() => secure.read('refresh');

  Future<void> signOut() async {
    _access = null;
    _expires = null;
    await secure.delete('refresh');
  }
}
