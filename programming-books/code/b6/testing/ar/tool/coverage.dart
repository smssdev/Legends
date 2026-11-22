import 'dart:io';

// Reads coverage/lcov.info, which `flutter test --coverage` writes, and prints the lines tested per file.
void main() {
  final hits = <String, (int, int)>{};
  String? file;
  for (final line in File('coverage/lcov.info').readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      file = line.substring(3);
    } else if (line.startsWith('DA:') && file != null) {
      final count = int.parse(line.split(',')[1]);
      final (hit, found) = hits[file] ?? (0, 0);
      hits[file] = (hit + (count > 0 ? 1 : 0), found + 1);
    }
  }
  var allHit = 0;
  var allFound = 0;
  for (final MapEntry(key: name, value: (hit, found)) in hits.entries) {
    stdout.writeln(
      '${name.padRight(28)}${'$hit/$found'.padLeft(8)}  ${(100 * hit / found).toStringAsFixed(0).padLeft(3)}%',
    );
    allHit += hit;
    allFound += found;
  }
  stdout.writeln(
    '${'all'.padRight(28)}${'$allHit/$allFound'.padLeft(8)}  ${(100 * allHit / allFound).toStringAsFixed(0).padLeft(3)}%',
  );
}
