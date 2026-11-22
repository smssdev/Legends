import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/security/tokens.dart';

class MemoryStore implements SecureStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

void main() {
  test('الرموز تنتهي، وتسجيل الخروج ينساها', () async {
    var clock = DateTime(2026, 11, 23, 9);
    final store = MemoryStore();
    final tokens = TokenStore(store, now: () => clock);
    await tokens.signedIn(
      access: 'a1',
      lifetime: const Duration(minutes: 15),
      refresh: 'r1',
    );
    expect(tokens.access, 'a1');

    clock = clock.add(const Duration(minutes: 16));
    expect(tokens.access, isNull);
    expect(await tokens.refreshToken(), 'r1');

    await tokens.signOut();
    expect(await tokens.refreshToken(), isNull);
    expect(store.values, isEmpty);
  });
}
