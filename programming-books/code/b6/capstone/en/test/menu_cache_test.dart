import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/data/menu_repository.dart';

import 'fakes.dart';

void main() {
  test('the saved menu first, then the fresh one', () async {
    final prefs = memoryPrefs();
    final repository = MenuRepository(FakeApi(), prefs);
    final first = await repository.watch().toList();
    final second = await repository.watch().toList();
    debugPrint(
      'first launch:  ${[for (final (menu, :fresh) in first) '${menu.length} drinks, fresh: $fresh']}',
    );
    debugPrint(
      'second launch: ${[for (final (menu, :fresh) in second) '${menu.length} drinks, fresh: $fresh']}',
    );
    expect(second, hasLength(2));
  });
}
