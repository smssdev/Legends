// Logs leave the device (crash reports, support emails): nothing secret goes in.
final _rules = <(RegExp, String Function(Match))>[
  (RegExp(r'(Bearer\s+)[A-Za-z0-9._~+/=-]+'), (m) => '${m[1]}***'),
  (RegExp(r'("(?:token|refresh|password)"\s*:\s*")[^"]*'), (m) => '${m[1]}***'),
  (
    RegExp(r'[A-Za-z0-9._%+-]+@([A-Za-z0-9.-]+\.[A-Za-z]{2,})'),
    (m) => '***@${m[1]}',
  ),
];

String redact(String line) =>
    _rules.fold(line, (text, rule) => text.replaceAllMapped(rule.$1, rule.$2));
