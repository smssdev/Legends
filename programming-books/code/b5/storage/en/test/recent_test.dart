import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:bit_app/projects_recent.dart';

void main() {
  test('the newest first, no repeats, five at most', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final recent = Recent(SharedPreferencesAsync());
    await recent.load();
    for (final word in ['a', 'b', 'c', 'd', 'e', 'f', 'b', ' ']) {
      await recent.add(word);
    }
    expect(recent.words, ['b', 'f', 'e', 'd', 'c']);

    final again = Recent(SharedPreferencesAsync());
    await again.load();
    expect(again.words, ['b', 'f', 'e', 'd', 'c']);
  });
}
