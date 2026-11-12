import 'package:flutter_test/flutter_test.dart';
import 'package:glm/features/club/team_data.dart';

// [Sprint 59 F6] The slot takes the lines the server sends with it, and nothing is refused from an older server.
void main() {
  test('a slot takes only the lines the server allows', () {
    final goal = Slot.fromJson({
      'role': 'GK',
      'line': 'gk',
      'x': 0,
      'y': 340,
      'allowed': ['gk'],
    });
    final mid = Slot.fromJson({
      'role': 'CM',
      'line': 'mid',
      'x': 500,
      'y': 340,
      'allowed': ['def', 'mid', 'att'],
    });
    expect(goal.takes('gk'), isTrue);
    expect(goal.takes('def'), isFalse);
    expect(mid.takes('att'), isTrue);
    expect(mid.takes('gk'), isFalse);
  });

  test('a slot without the rule refuses nothing', () {
    expect(Slot.fromJson({'role': 'CB', 'line': 'def', 'x': 200, 'y': 300}).takes('gk'), isTrue);
  });
}
