String plural(
  int count, {
  required String one,
  required String two,
  required String few,
  required String many,
}) {
  var rest = count % 100;
  return switch (count) {
    0 => 'لا $few',
    1 => '$one واحد',
    2 => two,
    _ when rest >= 3 && rest <= 10 => '$count $few',
    _ when rest >= 11 => '$count $many',
    _ => '$count $one',
  };
}

void main() {
  for (var n in [0, 1, 2, 3, 10, 11, 99, 100, 103]) {
    print(plural(n, one: 'كوب', two: 'كوبان', few: 'أكواب', many: 'كوباً'));
  }
}
