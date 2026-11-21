import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/l10n/app_localizations.dart';

void main() {
  test('plurals, prices and dates in both languages', () async {
    // In an app, flutter_localizations loads the date names; a plain test loads them itself.
    await initializeDateFormatting();
    // Without a context: the texts of one language, for a test.
    final en = lookupAppLocalizations(const Locale('en'));
    final ar = lookupAppLocalizations(const Locale('ar'));

    expect(
      [
        for (final n in [0, 1, 2, 3]) en.items(n),
      ],
      ['Your basket is empty', '1 item', '2 items', '3 items'],
    );
    expect(
      [
        for (final n in [0, 1, 2, 3, 11, 100]) ar.items(n),
      ],
      ['سلتك فارغة', 'قطعة واحدة', 'قطعتان', '3 قطع', '11 قطعة', '100 قطعة'],
    );
    expect(en.price(1500), '1,500 EGP');
    expect(ar.price(1500), '1,500 جنيه');
    expect(
      en.pickUpOn(DateTime(2026, 12, 3)),
      'Pick up on Thursday, December 3, 2026',
    );
    expect(
      ar.pickUpOn(DateTime(2026, 12, 3)),
      'الاستلام يوم الخميس، 3 ديسمبر 2026',
    );
  });
}
