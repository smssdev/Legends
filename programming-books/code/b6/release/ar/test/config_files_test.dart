import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('كل بيئة تعرّف المفاتيح نفسها', () {
    final files = Directory('config').listSync().whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    final keys = <String, Set<String>>{};
    for (final file in files) {
      final config =
          jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      keys[file.path] = config.keys.toSet();
      expect(
        (config['API_URL']! as String).startsWith('https://'),
        isTrue,
        reason: '${file.path} must use https',
      );
      debugPrint(
        '${file.path.padRight(22)} ${config['FLAVOR']}  ${config['API_URL']}',
      );
    }
    final first = keys.values.first;
    for (final MapEntry(key: path, value: names) in keys.entries) {
      expect(names, first, reason: '$path defines different keys');
    }
  });
}
