import 'story.dart';

/// [Sprint 44 A3] The director, as on the web (web/src/match/feed/director.ts, checked by web/scripts/feed.mjs; the same
/// cases in test/feed_test.dart): which cutaways follow a scene, as a pure function of the minute's story, the device's
/// tier and the time left. A goal: the scorers' fans, their coach's joy, then the other coach. A red card: tempers, then
/// the coach. A chance blasted over: the coach loses it. The moods are the server's (tick.moods) when expressive.
enum Tier { low, mid, high }

typedef Cut = ({String name, Map<String, Object?> data, double dur});

const _moods = ['joy', 'cheer', 'angry', 'worried', 'sad', 'surprise'];

List<Cut> director(FeedStory s, {required int tick, Map<String, String> moods = const {}, required double total, required double sceneT, required Tier tier,
    Map<String, String>? looks, int seed = 1}) {
  if (s.scene == null || tier == Tier.low) return const [];
  final other = s.side == 'home' ? 'away' : 'home';
  String look(String side) => looks?[side] ?? (side == 'home' ? 'C1' : 'C2');
  String felt(String side, String fallback) => _moods.contains(moods[side]) ? moods[side]! : fallback;
  Cut coach(String side, String fallback) => (name: 'coachReact', data: {'side': side, 'look': look(side), 'mood': felt(side, fallback)}, dur: sceneTime['coachReact']!.$1);
  Cut crowd() => (name: 'crowd', data: {'side': s.side, 'v': seed * 7 + tick, 'count': tier == Tier.high ? 110 : 60, 'flares': tier == Tier.high}, dur: sceneTime['crowd']!.$1);
  final d = s.data;
  var list = <Cut>[];
  if (s.goal) {
    list = [crowd(), coach(s.side, 'joy'), coach(other, 'angry')];
  } else if (s.scene == 'card' && d['type'] == 'red' && ['brawl', 'spit'].contains(d['drama'])) {
    list = [coach(s.side, 'angry')];
  } else if (s.scene == 'card') {
    list = d['type'] == 'red'
        ? [(name: 'brawl', data: {'side': s.side, 'v': seed * 13 + tick}, dur: sceneTime['brawl']!.$1), coach(s.side, 'angry')]
        : tier == Tier.high
            ? [coach(s.side, 'angry')]
            : [];
  } else if (s.scene == 'miss' && d['how'] == 'over') {
    list = [(name: 'meltdown', data: {'side': s.side, 'v': seed * 5 + tick}, dur: sceneTime['meltdown']!.$1)];
  } else if (['miss', 'save', 'penalty', 'freekick'].contains(s.scene)) {
    list = [coach(s.side, 'worried')];
  } else if (s.scene == 'whistle' && d['name'] == 'halftime') {
    list = [(name: 'tunnel', data: {'side': 'home'}, dur: sceneTime['tunnel']!.$1)];
  } else if (s.scene == 'whistle' && d['name'] == 'fulltime') {
    list = [(name: 'handshake', data: {'side': 'home'}, dur: sceneTime['handshake']!.$1), coach('home', 'idle'), coach('away', 'idle')];
  } else if (s.scene == 'var') {
    list = [coach(s.side, 'angry'), coach(other, 'joy')];
  }
  list = list.take(tier == Tier.high ? 3 : 1).toList();
  // What fits: a goal keeps room for its replay (4.5 s), the rest for the commentator's line (1.2 s).
  final keep = s.goal ? 4.5 : 1.2;
  final fit = <Cut>[];
  var used = 0.0;
  for (final c in list) {
    if (sceneT + used + c.dur + keep <= total) {
      fit.add(c);
      used += c.dur;
    }
  }
  return fit;
}
