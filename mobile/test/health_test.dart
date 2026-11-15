import 'package:flutter_test/flutter_test.dart';
import 'package:glm/features/health/health.dart';
import 'package:glm/features/home/home_screen.dart' show latinDigits;

void main() {
  test('a version is older by its numbers, not its letters', () {
    expect(olderThan('0.1.0', '0.2.0'), isTrue);
    expect(olderThan('1.2.9', '1.2.10'), isTrue);
    expect(olderThan('1.2.10', '1.2.9'), isFalse);
    expect(olderThan('1.0.0+7', '1.0.0'), isFalse);
    expect(olderThan('2.0', '1.9.9'), isFalse);
  });

  test("dates keep the game's Western digits", () {
    expect(latinDigits('الثلاثاء ٧:٠٥ م'), 'الثلاثاء 7:05 م');
  });

  // [Sprint 71 N4] An update required (older than the server's minimum), ready (a newer app on the site), or neither.
  test('an older app is told an update is ready, and required only under the minimum', () {
    expect(appAge('2.3.0', '2.5.0', '2.5.0'), (required: true, ready: '2.5.0'));
    expect(appAge('2.4.0', '2.0.0', '2.5.0'), (required: false, ready: '2.5.0'));
    expect(appAge('2.5.0', '2.0.0', '2.5.0'), (required: false, ready: null));
    expect(appAge('2.5.0', '2.0.0', null), (required: false, ready: null));
    expect(appAge('2.6.0', '2.0.0', '2.5.0'), (required: false, ready: null));
  });
}
