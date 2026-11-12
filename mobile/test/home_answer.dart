import 'dart:convert';
import 'dart:io';

/// [Sprint 59 F1] A `/home` answer for a test: the server's captured one (test/fixtures/home.json, every field the
/// contract requires) with the test's own values laid over it. A slot's club, league and next match take the captured
/// club slot's fields under the test's own (only where the test gives one); a value the test leaves null keeps the
/// captured one.
Map<String, dynamic> homeAnswer(Map<String, dynamic> overrides) {
  final base = jsonDecode(File('test/fixtures/home.json').readAsStringSync()) as Map<String, dynamic>;
  Map<String, dynamic> merge(Map<String, dynamic> a, Map<String, dynamic> b) => {
    ...a,
    for (final e in b.entries)
      if (e.value != null || a[e.key] == null)
        e.key: a[e.key] is Map<String, dynamic> && e.value is Map<String, dynamic>
            ? merge(a[e.key] as Map<String, dynamic>, e.value as Map<String, dynamic>)
            : e.value,
  };
  final captured = (base['slots'] as List<dynamic>).cast<Map<String, dynamic>>().firstWhere((s) => s['state'] == 'club');
  Map<String, dynamic> slot(Map<String, dynamic> s) => {
    'pending': 0,
    for (final k in ['position', 'teams', 'opens_at', 'progress_bp', 'unlock_coins']) k: null,
    ...s,
    for (final k in ['league', 'club', 'next_match'])
      if (s[k] is Map<String, dynamic>) k: merge(captured[k] as Map<String, dynamic>, s[k] as Map<String, dynamic>),
  };
  return {
    ...merge(base, {...overrides}..remove('slots')),
    'slots': [
      for (final s in (overrides['slots'] ?? base['slots']) as List<dynamic>) slot(Map<String, dynamic>.from(s as Map<dynamic, dynamic>)),
    ],
  };
}
