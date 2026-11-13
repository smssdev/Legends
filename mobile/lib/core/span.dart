import '../l10n/app_localizations.dart';

/// [Sprint 60 F8] A time left in words, by its two largest units (years, months, days, hours, minutes): «3 سنوات
/// وشهران», «يومان و5 ساعات», «12 دقيقة» («3 years 2 months» in English), with Arabic's own plural forms. One way for
/// every screen, so a long wait never runs past its line (1144 days was «1144 يوم»). Under a minute is a minute.
String spanText(L l, Duration d) {
  var m = d.inMinutes < 1 ? 1 : d.inMinutes;
  const day = 24 * 60, month = 30 * day, year = 365 * day;
  final parts = <String>[];
  for (final (size, word) in [(year, l.spanYears), (month, l.spanMonths), (day, l.spanDays), (60, l.spanHours), (1, l.spanMinutes)]) {
    final n = m ~/ size;
    if (n > 0) {
      parts.add(word(n));
      m -= n * size;
    } else if (parts.isNotEmpty) {
      break; // the next unit is zero: «سنة» not «سنة و0 أشهر», and nothing smaller after it
    }
    if (parts.length == 2) break;
  }
  return parts.length == 1 ? parts.single : l.spanJoin(parts[0], parts[1]);
}
