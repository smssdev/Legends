import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/projects_sorted.dart';

void main() {
  test('الترتيبات الثلاثة', () {
    List<String> ids(Sort s) => [for (final n in sortNotes(samples, s)) n.id];
    expect(ids(Sort.newest), ['3', '2', '4', '1']);
    expect(ids(Sort.oldest), ['1', '4', '2', '3']);
    expect(ids(Sort.az), ['2', '3', '1', '4']);
  });
}
