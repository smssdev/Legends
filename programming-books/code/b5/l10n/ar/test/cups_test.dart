import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/l10n/app_localizations.dart';

void main() {
  test('كل صيغ الجمع', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final ar = lookupAppLocalizations(const Locale('ar'));
    expect(
      [
        for (final n in [0, 1, 2, 11]) en.cups(n),
      ],
      ['No cups yet', '1 cup', '2 cups', '11 cups'],
    );
    expect(
      [
        for (final n in [0, 1, 2, 3, 10, 11, 99, 100, 101]) ar.cups(n),
      ],
      [
        'لا أكواب بعد',
        'كوب واحد',
        'كوبان',
        '3 أكواب',
        '10 أكواب',
        '11 كوبًا',
        '99 كوبًا',
        '100 كوب',
        '101 كوب',
      ],
    );
  });
}
