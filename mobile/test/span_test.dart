import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/span.dart';
import 'package:glm/l10n/app_localizations_ar.dart';
import 'package:glm/l10n/app_localizations_en.dart';

void main() {
  final ar = LAr(), en = LEn();
  test('the two largest units, with Arabic plural forms', () {
    expect(spanText(ar, const Duration(days: 1144)), '3 سنوات وشهر');
    expect(spanText(ar, const Duration(days: 2, hours: 5)), 'يومان و5 ساعات');
    expect(spanText(ar, const Duration(days: 11)), '11 يوماً');
    expect(spanText(ar, const Duration(hours: 1, minutes: 30)), 'ساعة و30 دقيقة');
    expect(spanText(ar, const Duration(minutes: 12)), '12 دقيقة');
    expect(spanText(ar, const Duration(seconds: 20)), 'دقيقة');
    expect(spanText(ar, const Duration(days: 365)), 'سنة');
  });
  test('in English', () {
    expect(spanText(en, const Duration(days: 1144)), '3 years 1 month');
    expect(spanText(en, const Duration(hours: 2)), '2 hours');
  });
}
