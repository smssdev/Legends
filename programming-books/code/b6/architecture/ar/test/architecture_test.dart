import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// ما لا يحق لملف في المجال أن يستورده أبداً.
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
  test('المجال لا يستورد Flutter ولا البيانات ولا العرض', () {
    // المجال لا يستورد إلا Dart وملفات المجال الأخرى.
    expect(violations('lib/features'), isEmpty);
  });
}
