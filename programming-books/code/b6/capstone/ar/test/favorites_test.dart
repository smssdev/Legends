import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/state/favorites.dart';
import 'package:bit_app/state/providers.dart';

import 'fakes.dart';

void main() {
  test('المفضلات تُتذكَّر', () async {
    final prefs = memoryPrefs();
    final first = ProviderContainer.test(
      overrides: [prefsProvider.overrideWithValue(prefs)],
    );
    await first.read(favoritesProvider.future);
    await first.read(favoritesProvider.notifier).toggle('latte');
    await first.read(favoritesProvider.notifier).toggle('cake');
    await first.read(favoritesProvider.notifier).toggle('latte');
    final later = ProviderContainer.test(
      overrides: [prefsProvider.overrideWithValue(prefs)],
    );
    debugPrint(
      'after a restart: ${await later.read(favoritesProvider.future)}',
    );
    expect(await later.read(favoritesProvider.future), {'cake'});
  });
}
