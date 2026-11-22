import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// A feature may import another feature's domain, and nothing else of it.
List<String> crossFeature(String root) {
  final found = <String>[];
  for (final file
      in Directory(root)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
    final feature = RegExp(r'features/(\w+)/').firstMatch(file.path)!.group(1);
    for (final line in file.readAsLinesSync().where(
      (l) => l.startsWith('import '),
    )) {
      final other =
          RegExp(r'features/(\w+)/(\w+)/').firstMatch(line) ??
          RegExp(r"'\.\./\.\./(\w+)/(\w+)/").firstMatch(line);
      if (other != null &&
          other.group(1) != feature &&
          other.group(2) != 'domain') {
        found.add('${file.path}: $line');
      }
    }
  }
  return found;
}

void main() {
  test('features talk to each other only through their domain', () {
    expect(crossFeature('lib/features'), isEmpty);
    expect(crossFeature('test/fixtures_features'), hasLength(1));
  });
}
