import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:glm/router.dart';

// [Sprint 59 F11] A push or an inbox message opens only one of the app's own pages.
void main() {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/inbox', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/leagues/:id/market', builder: (_, _) => const SizedBox()),
    ],
  );

  test('the router table decides', () {
    expect(knownRoute(router, '/inbox'), isTrue);
    expect(knownRoute(router, '/leagues/7/market'), isTrue);
    expect(knownRoute(router, '/leagues/7/market?tab=bids'), isTrue);
    expect(knownRoute(router, '/admin'), isFalse);
    expect(knownRoute(router, 'https://evil.example/inbox'), isFalse);
    expect(knownRoute(router, '//evil.example/inbox'), isFalse);
    expect(knownRoute(router, 'inbox'), isFalse);
    expect(knownRoute(router, null), isFalse);
  });
}
