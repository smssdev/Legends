import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/api/api_client.dart';

/// [Sprint 74 P8] An answer kept a while after its last screen goes: back within the time asks nothing; after it, or
/// after an action invalidates it, it is asked for again. A failure is never kept.
void main() {
  test('kept while the time runs, asked again after it, and at once when invalidated', () async {
    var asked = 0;
    final answer = FutureProvider.autoDispose<int>((ref) async {
      final n = ++asked;
      ref.staysFor(const Duration(milliseconds: 120));
      return n;
    });
    final c = ProviderContainer();
    addTearDown(c.dispose);

    var screen = c.listen(answer, (_, _) {});
    expect(await c.read(answer.future), 1);
    screen.close(); // the screen goes
    await Future<void>.delayed(const Duration(milliseconds: 30));
    screen = c.listen(answer, (_, _) {}); // back in time: the same answer, no request
    expect(await c.read(answer.future), 1);
    expect(asked, 1);

    c.invalidate(answer); // an action: asked again at once
    expect(await c.read(answer.future), 2);

    screen.close();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    screen = c.listen(answer, (_, _) {}); // back too late: asked again
    expect(await c.read(answer.future), 3);
    screen.close();
  });

  test('a failure is not kept: the next screen asks again', () async {
    var asked = 0;
    final answer = FutureProvider.autoDispose<int>((ref) async {
      if (++asked == 1) throw StateError('no network');
      ref.staysFor(const Duration(milliseconds: 120));
      return asked;
    });
    final c = ProviderContainer();
    addTearDown(c.dispose);
    var screen = c.listen(answer, (_, _) {});
    await expectLater(c.read(answer.future), throwsStateError);
    screen.close();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    screen = c.listen(answer, (_, _) {});
    expect(await c.read(answer.future), 2);
    screen.close();
  });
}
