part of 'match_data.dart';

/// What the app needs of a finished match: the coach's report, or the recap for a member who coaches neither side.
class MatchReport {
  const MatchReport({
    required this.score,
    this.result,
    this.side,
    this.reasons = const [],
    this.improve,
    this.verdict = const [],
    this.motm,
    this.stats = const {},
    this.moments = const [],
    this.ratings = const {},
  });

  /// [Sprint 59 F1] The coach's report (`MatchCoachReport`), read through its generated model.
  factory MatchReport.fromReport(Object? json) {
    final r = MatchCoachReport.fromJson(json);
    ({String title, String text, String big}) note(ReportNote n) => (title: n.title, text: n.text, big: n.big);
    return MatchReport(
      score: (r.score['home'] ?? 0, r.score['away'] ?? 0),
      result: r.result,
      side: r.side,
      reasons: [for (final n in r.reasons) note(n)],
      improve: r.improve == null ? null : note(r.improve!),
      verdict: [for (final v in r.verdict) (tag: v.tag, text: v.text)],
      motm: r.manOfTheMatch?.name,
      stats: {'home': r.stats.home, 'away': r.stats.away},
      moments: [
        for (final t in r.timeline.whereType<Map<String, dynamic>>())
          if (t['type'] case 'goal' || 'card' || 'sub' || 'injury' || 'penalty')
            MatchEvent.fromJson(
              t,
              minute: ((t['minute'] is List<dynamic> ? (t['minute'] as List<dynamic>)[0] : t['minute']) as num? ?? 0).toInt(),
              added: t['minute'] is List<dynamic> && (t['minute'] as List<dynamic>).length > 1
                  ? ((t['minute'] as List<dynamic>)[1] as num).toInt()
                  : 0,
            ),
      ],
      ratings: {
        'home': [for (final p in r.ratings.home) (name: p.name, rating: p.rating)],
        'away': [for (final p in r.ratings.away) (name: p.name, rating: p.rating)],
      },
    );
  }

  factory MatchReport.fromRecap(Map<String, dynamic> j) => MatchReport(
    score: _score(j['score']),
    result: j['result'] as String?,
    side: j['side'] as String?,
    motm: j['man_of_the_match'] is Map<dynamic, dynamic> ? '${(j['man_of_the_match'] as Map<dynamic, dynamic>)['name'] ?? ''}' : null,
    stats: _stats(j['stats']),
    moments: [
      for (final m in (j['moments'] as List<dynamic>? ?? const []))
        MatchEvent(
          type: '${(m as Map<dynamic, dynamic>)['type']}',
          team: m['team'] as String?,
          minute: (m['minute'] as num?)?.toInt() ?? 0,
          color: m['color'] as String?,
          text: _moment(m),
          raw: Map<String, dynamic>.from(m),
        ),
    ],
    ratings: {
      for (final side in ['home', 'away'])
        side: [
          for (final r in ((j['best'] as Map<dynamic, dynamic>?)?[side] as List<dynamic>? ?? const []))
            (name: '${(r as Map<dynamic, dynamic>)['name']}', rating: (r['rating'] as num?)?.toInt() ?? 0),
        ],
    },
  );

  /// The report with the recap's key moments, which carry the players' names.
  MatchReport withMoments(MatchReport recap) => MatchReport(
    score: score,
    result: result,
    side: side,
    reasons: reasons,
    improve: improve,
    verdict: verdict,
    motm: motm,
    stats: recap.stats,
    moments: recap.moments,
    ratings: ratings,
  );

  final (int, int) score;
  final String? result, side, motm;
  final List<({String title, String text, String big})> reasons;
  final ({String title, String text, String big})? improve;
  final List<({String tag, String text})> verdict;
  final Map<String, Map<String, int>> stats;
  final List<MatchEvent> moments;
  final Map<String, List<({String name, int rating})>> ratings;
}

/// A recap moment in a line (names in English): the scorer and his assist, who came on for whom, the booked player.
String _moment(Map<dynamic, dynamic> m) {
  final who = m['player'] as String? ?? '', other = m['other'] as String?;
  return switch (m['type']) {
    'goal' => other == null ? who : '$who ($other)',
    'sub' => other == null ? who : '$other ⇄ $who',
    _ => who,
  };
}

Map<String, Map<String, int>> _stats(Object? s) => {
  for (final side in ['home', 'away'])
    side: {
      for (final e in (((s as Map<dynamic, dynamic>?)?[side] as Map<dynamic, dynamic>?) ?? const {}).entries)
        if (e.value is num) '${e.key}': (e.value as num).toInt(),
    },
};

class MatchRepository {
  MatchRepository(this._api);

  final ApiClient _api;

  Future<MatchView> show(int id) async => MatchView.fromJson(await _api.get('/matches/$id'));
  Future<LiveSync> live(int id, int since) async => LiveSync.fromJson(await _api.get('/matches/$id/live', query: {'since': since}));

  /// An order for the next minute not yet made; only in a window (the server answers 409 otherwise, with why).
  /// [Sprint 59 F5] With the key LiveOrders holds for this order (the same on a retry).
  Future<void> order(int id, Map<String, Object> order, {required String key}) =>
      _api.post('/matches/$id/actions', {...order, 'idempotency_key': key});
  Future<void> ready(int id) => _api.post('/matches/$id/ready');
  Future<void> react(int id, String key, {String? target}) => _api.post('/matches/$id/reactions', {'key': key, 'target': ?target});
  Future<void> say(int id, String body) => _api.post('/matches/$id/chat', {'body': body});

  /// The coach's own report; the quick recap for a member who coaches neither side (403 on the report).
  Future<MatchReport> report(int id, {required bool coach}) async {
    final recap = _api.get('/matches/$id/recap');
    if (!coach) return MatchReport.fromRecap(await recap);
    final report = await _api.get('/matches/$id/report');
    return MatchReport.fromReport(report).withMoments(MatchReport.fromRecap(await recap));
  }

  /// My matches being played now, in every league (the switcher).
  Future<List<({int id, String home, String away})>> mine() async => [
    for (final m in ((await _api.get('/matches/live'))['matches'] as List<dynamic>? ?? const []))
      (id: (m as Map<dynamic, dynamic>)['id'] as int, home: '${m['home']}', away: '${m['away']}'),
  ];
}

final matchRepositoryProvider = Provider<MatchRepository>((ref) => MatchRepository(ref.watch(apiProvider)));
final matchProvider = FutureProvider.autoDispose.family<MatchView, int>((ref, id) => ref.read(matchRepositoryProvider).show(id));
final myLiveMatchesProvider = FutureProvider.autoDispose((ref) => ref.read(matchRepositoryProvider).mine());
final reportProvider = FutureProvider.autoDispose.family<MatchReport, (int, bool)>(
  (ref, k) => ref.read(matchRepositoryProvider).report(k.$1, coach: k.$2),
);
