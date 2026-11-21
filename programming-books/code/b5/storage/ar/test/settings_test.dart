import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:bit_app/settings_app.dart';

void main() {
  setUp(() {
    // A pretend disk, in memory: every test starts with nothing saved.
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('الإعداد يبقى بعد فتح التطبيق من جديد', () async {
    final first = Settings(SharedPreferencesAsync());
    await first.load();
    expect(first.dark, isFalse);
    await first.setDark(true);

    // A new Settings is the app opened again: it reads what the first one saved.
    final again = Settings(SharedPreferencesAsync());
    await again.load();
    expect(again.dark, isTrue);
    expect(again.big, isFalse);
  });
}
