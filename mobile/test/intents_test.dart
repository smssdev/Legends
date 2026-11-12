import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/api/intents.dart';
import 'package:shared_preferences/shared_preferences.dart';

// [Sprint 59 F10] A pending key survives the app closing, until the request succeeds or a day passes.
void main() {
  final t0 = DateTime.utc(2026, 11, 12, 10);

  test('a failed request keeps its key on the phone, and the retry after a restart sends it again', () async {
    SharedPreferences.setMockInitialValues({});
    Intents.load(await SharedPreferences.getInstance(), now: t0);
    String? sent;
    await expectLater(Intents.run('buy:1:9', (k) async => throw StateError(sent = k), now: t0), throwsStateError);
    expect((await SharedPreferences.getInstance()).getString(Intents.storeKey), contains(sent));

    // The app restarts: the key is read back and sent again; once it succeeds it is gone.
    Intents.load(await SharedPreferences.getInstance(), now: t0.add(const Duration(hours: 2)));
    expect(Intents.pending('buy:1:9'), sent);
    final again = await Intents.run('buy:1:9', (k) async => k, now: t0.add(const Duration(hours: 2)));
    expect(again, sent);
    expect(Intents.pending('buy:1:9'), isNull);
    expect((await SharedPreferences.getInstance()).getString(Intents.storeKey), isNull);
  });

  test('a key left over a day is forgotten', () async {
    SharedPreferences.setMockInitialValues({});
    Intents.load(await SharedPreferences.getInstance(), now: t0);
    String? first;
    await expectLater(Intents.run('build:1:north', (k) async => throw StateError(first = k), now: t0), throwsStateError);
    Intents.load(await SharedPreferences.getInstance(), now: t0.add(const Duration(hours: 25)));
    expect(Intents.pending('build:1:north'), isNull);
    final next = await Intents.run('build:1:north', (k) async => k, now: t0.add(const Duration(hours: 25)));
    expect(next, isNot(first));
  });
}
