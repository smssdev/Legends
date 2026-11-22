import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// قيم خام مكانها lib/design، لا الشاشات أبداً.
final rules = {
  'a raw colour': RegExp(r'Color\(0x|Colors\.(?!transparent)'),
  'a raw spacing': RegExp(r'EdgeInsets\.\w+\([^)]*\b\d'),
  'a raw font size': RegExp(r'fontSize:'),
};

List<String> violations(String folder) => [
  for (final file
      in Directory(folder)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart')))
    for (final (i, line) in file.readAsLinesSync().indexed)
      for (final MapEntry(key: what, value: pattern) in rules.entries)
        if (pattern.hasMatch(line)) '${file.path}:${i + 1}: $what',
];

void main() {
  test('الشاشات تستخدم الرموز، لا القيم الخام', () {
    expect(violations('lib/screens'), isEmpty);
  });
}
