import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// What a domain file may never import.
const forbidden = [
  'package:flutter/',
  'package:material_ui/',
  'package:provider/',
  'package:http/',
  '/data/',
  '/presentation/',
];

/// Every import in a domain folder that breaks the rule, as "file: import".
List<String> violations(String root) => [
  for (final file in Directory(
    root,
  ).listSync(recursive: true).whereType<File>())
    if (file.path.contains('/domain/') && file.path.endsWith('.dart'))
      for (final line in file.readAsLinesSync())
        if (line.startsWith('import ') && forbidden.any(line.contains))
          '${file.path}: $line',
];

void main() {
  test('the domain imports no Flutter, no data and no presentation', () {
    // The domain imports only Dart and other domain files.
    expect(violations('lib/features'), isEmpty);
  });
}
