import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:bit_app/projects_receipt.dart';

void main() {
  test('one receipt, three audiences', () async {
    await initializeDateFormatting();
    expect(totalIn('en'), 'EGP1,250');
    //  ,  : spaces that never break a line; ‏: an invisible right-to-left mark.
    expect(timeIn('en'), 'Dec 3, 2026 9:41 AM');
    expect(totalIn('ar'), '‏1,250 EGP');
    expect(totalIn('ar_EG'), '‏١٬٢٥٠ EGP');
    expect(timeIn('ar_EG'), '٣ ديسمبر ٢٠٢٦ ٩:٤١ ص');
  });
}
