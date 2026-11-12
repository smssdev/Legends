import '../match_data.dart';
import 'story_words.dart';

/// [Sprint 44 A2, Sprint 57 F1] What one minute becomes on the app's broadcast: the server's story (tick.story, the same
/// as the web's), written in the app's language. The commentary lines are the server's too (each event's text).

/// Each scene's own length and its key moment, in seconds (web/src/match/feed/timing.ts: keep the two in step).
const sceneTime = <String, (double, double)>{
  'goal': (6.0, 3.0), 'save': (5.4, 2.9), 'penalty': (6.8, 4.05), 'freekick': (5.2, 2.65), 'card': (6.6, 3.4), 'coach': (4.6, 1.0), 'sub': (5.0, 0.8),
  'offside': (4.2, 1.5), 'corner': (4.6, 1.75), 'injury': (5.6, 0.4), 'foul': (5.2, 1.5), 'whistle': (3.6, 0.6), 'miss': (5.0, 2.9), 'blocked': (4.8, 2.6), 'board': (3.0, 0.5),
  'crowd': (2.6, 0.3), 'coachReact': (2.4, 0.2), 'brawl': (2.8, 0.2), 'tunnel': (2.8, 0.2), 'handshake': (3.0, 0.2),
  'var': (8.2, 6.4),
  'clearance': (4.2, 2.4), 'trap': (3.6, 1.5), 'rant': (3.6, 0.6), 'slip': (3.6, 1.0), 'meltdown': (2.8, 0.3),
};

/// A player as the broadcast names him: his name (always in English, decision 2026-11-01), his shirt number, his side.
typedef CastMember = ({String name, int no, String side});

class FeedStory {
  FeedStory({this.scene, this.side = 'home', this.data = const {}, this.head = '', this.who = '', this.sub = '', this.pre, this.goal = false});

  /// The scene to play (sceneTime's keys), or none (a quiet minute, a brief one).
  final String? scene;
  final String side;
  final Map<String, Object?> data;

  /// The lower third: the moment, the player, a line under.
  final String head, who, sub;

  /// What the lower third says until the key moment (the shot, the kick), or none when there is nothing to hide.
  final ({String head, String who, String sub})? pre;
  final bool goal;

  double get length => scene == null ? 0 : sceneTime[scene]!.$1;
  double get keyAt => scene == null ? 0 : sceneTime[scene]!.$2;
}

/// A text of the server's story (App\Simulator\MomentStory, StoryText in openapi.yaml), written for this screen: a
/// string is a key of the game's dictionary (its Arabic, or its English from storyWords), {p} a player by id, {c} a club
/// by side, {r} as it is, {t, v} a key with its parts, {j, by} parts joined.
String storyText(Object? x, {required Map<String, CastMember> cast, required Map<String, String> clubs, bool ar = true}) {
  String w(Object? y) => storyText(y, cast: cast, clubs: clubs, ar: ar);
  if (x == null) return '';
  if (x is String) return x.isEmpty || ar ? x : storyWords[x] ?? x;
  if (x is! Map) return '$x';
  if (x.containsKey('p')) return x['p'] == null ? '' : cast['${x['p']}']?.name ?? '';
  if (x.containsKey('c')) return clubs['${x['c']}'] ?? '';
  if (x.containsKey('r')) return '${x['r']}';
  if (x.containsKey('t')) {
    var out = w('${x['t']}');
    for (final (i, v) in ((x['v'] as List?) ?? const []).indexed) {
      out = out.replaceAll('{v$i}', w(v));
    }
    return out;
  }
  if (x.containsKey('j')) return [for (final v in (x['j'] as List? ?? const [])) w(v)].join(w(x['by']));
  return '';
}

/// [Sprint 57 F1] The minute's story as the server tells it (tick.story): the scene, its side and who is in it, the
/// lower third's three lines, and what it says before the key moment. Nothing is decided here. [cast]: each player id's
/// name, number and side; [clubs]: each side's name; [ar]: the words in Arabic.
FeedStory feedStory(LiveTick tick, {required Map<String, CastMember> cast, required Map<String, String> clubs, bool ar = true}) {
  final s = tick.story;
  if (s == null) return FeedStory();
  String w(Object? x) => storyText(x, cast: cast, clubs: clubs, ar: ar);
  final data = <String, Object?>{...(s['data'] as Map? ?? const {}).cast<String, Object?>()};
  // The shirt numbers as the clips print them; the whistle's board in the clip's own shape.
  for (final k in ['no', 'passNo', 'defNo', 'victimNo', 'inNo', 'outNo']) {
    if (data.containsKey(k)) data[k] = '${data[k] ?? ''}';
  }
  if (data['big'] != null) data['big'] = w(data['big']);
  if (data['tactic'] != null) data['tactic'] = w(data['tactic']);
  if (data['score'] is List) {
    final sc = data.remove('score') as List;
    data['home'] = sc[0];
    data['away'] = sc[1];
  }
  if (data['stats'] is List) {
    data['stats'] = [for (final r in data['stats'] as List) (w((r as List)[0]), (r[1] as num).toInt(), (r[2] as num).toInt())];
  }
  final pre = s['pre'] as Map?;
  return FeedStory(
    scene: s['scene'] as String?, side: '${s['side'] ?? 'home'}', data: data,
    head: w(s['head']), who: w(s['who']), sub: w(s['sub']),
    pre: pre == null ? null : (head: w(pre['head']), who: w(pre['who']), sub: w(pre['sub'])),
    goal: s['goal'] == true,
  );
}

/// The rain, from the match's seed as the server decides it (MomentClock::rainy: one match in six). Keep them in step.
bool rainy(int? seed) => seed != null && seed % 6 == 1;
