import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('[Sprint 63 G13] the sound in two levels as on the site: kept on the phone, from 0 to 100', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    ProviderContainer box() => ProviderContainer(overrides: [preferencesProvider.overrideWithValue(prefs)]);

    final c = box();
    addTearDown(c.dispose);
    expect((c.read(settingsProvider).soundUi, c.read(settingsProvider).soundStadium), (80, 80));
    await c.read(settingsProvider.notifier).setLevel('ui', 35);
    await c.read(settingsProvider.notifier).setLevel('stadium', 140);
    expect((c.read(settingsProvider).soundUi, c.read(settingsProvider).soundStadium), (35, 100));

    // The next start reads them back.
    final again = box();
    addTearDown(again.dispose);
    expect((again.read(settingsProvider).soundUi, again.read(settingsProvider).soundStadium), (35, 100));
  });
}
