void main() {
  var size = 'M';

  // No break needed: Dart never runs into the next case.
  switch (size) {
    case 'S':
      print('Small cup');
    case 'M':
      print('Medium cup');
    case 'L':
      print('Large cup');
    default:
      print('Unknown size');
  }

  // A switch expression produces a value. The first pattern that matches wins.
  var day = 'friday';
  var kind = switch (day) {
    'friday' || 'saturday' => 'Weekend',
    _ => 'Workday',
  };
  print(kind);

  for (var score in [95, 83, 71, 40]) {
    var grade = switch (score) {
      // >= 90 is a pattern: it matches any value that is at least 90.
      >= 90 => 'A',
      >= 80 => 'B',
      >= 70 => 'C',
      >= 50 => 'D',
      // _ matches anything: the case for everyone else.
      _ => 'F',
    };
    print('$score -> $grade');
  }
}
