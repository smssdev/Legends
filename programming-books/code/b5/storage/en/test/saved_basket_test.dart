import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:bit_app/projects_saved_basket.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('the basket survives, and a damaged value does not crash', () async {
    final first = Basket(SharedPreferencesAsync());
    await first.load();
    await first.add(1);
    await first.add(1);
    await first.add(4);

    final again = Basket(SharedPreferencesAsync());
    await again.load();
    expect(again.count, 3);
    expect(again.total, 150);
  });

  test(
    'a damaged value, or one from another version, gives an empty basket',
    () async {
      for (final saved in [
        'not json',
        '[1, 2]',
        '{"version": 2, "items": {"1": 3}}',
        '{"version": 1, "items": {"1": "x"}}',
      ]) {
        await SharedPreferencesAsync().setString('basket', saved);
        final basket = Basket(SharedPreferencesAsync());
        await basket.load();
        expect(basket.count, 0, reason: saved);
      }
    },
  );
}
