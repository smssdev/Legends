import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:bit_app/favourites_app.dart';

void main() {
  test('القلوب تبقى بعد فتح التطبيق من جديد', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final first = Favourites(SharedPreferencesAsync());
    await first.load();
    await first.toggle(2);
    await first.toggle(4);
    await first.toggle(2);

    final again = Favourites(SharedPreferencesAsync());
    await again.load();
    expect(again.has(4), isTrue);
    expect(again.has(2), isFalse);
    expect(await SharedPreferencesAsync().getStringList('favourites'), ['4']);
  });
}
