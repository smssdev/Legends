import 'package:flutter_test/flutter_test.dart';
import 'package:glm/features/match/feed/director.dart';
import 'package:glm/features/match/feed/story.dart';
import 'package:glm/features/match/match_data.dart';

/// [Sprint 44 A3] The app's director against the web's own cases (web/scripts/feed.mjs): the same cutaways, by tier and
/// by the time left, on every screen. And the minute's story (A2) read from the server's moment.
void main() {
  const moods = {'home': 'joy', 'away': 'sad'};
  final goal = FeedStory(scene: 'goal', goal: true, side: 'home');
  String names(List<Cut> cuts) => cuts.map((c) => c.name).join(',');
  List<Cut> cut(FeedStory s, double total, double sceneT, Tier tier, {Map<String, String> m = moods, Map<String, String>? looks, int seed = 1}) =>
      director(s, tick: 12, moods: m, total: total, sceneT: sceneT, tier: tier, looks: looks, seed: seed);

  test('the director: the web\'s cases', () {
    expect(cut(goal, 30, 6, Tier.low), isEmpty, reason: 'low tier: no cutaways');
    expect(names(cut(goal, 30, 6, Tier.mid)), 'crowd', reason: 'mid tier: one cutaway, the crowd first');
    expect(names(cut(goal, 30, 6, Tier.high)), 'crowd,coachReact,coachReact', reason: 'high tier: crowd then both coaches');
    final [_, mine, theirs] = cut(goal, 30, 6, Tier.high, looks: {'home': 'C3'});
    expect((mine.data['side'], mine.data['look'], mine.data['mood']), ('home', 'C3', 'joy'));
    expect((theirs.data['side'], theirs.data['look'], theirs.data['mood']), ('away', 'C2', 'sad'));
    final calm = cut(goal, 30, 6, Tier.high, m: {'home': 'idle'});
    expect((calm[1].data['mood'], calm[2].data['mood']), ('joy', 'angry'), reason: 'no expressive mood: joy and anger');
    expect(cut(goal, 6 + 2.6 + 4.5, 6, Tier.high), hasLength(1), reason: 'a short minute keeps only what fits');
    expect(cut(goal, 6 + 2.3 + 4.5, 6, Tier.high), isEmpty, reason: 'no room: no cutaway');
    expect(names(cut(FeedStory(scene: 'card', side: 'away', data: {'type': 'red'}), 30, 4.4, Tier.high)), 'brawl,coachReact');
    expect(cut(FeedStory(scene: 'card', side: 'away', data: {'type': 'yellow'}), 30, 4.4, Tier.mid), isEmpty);
    for (final drama in ['brawl', 'spit']) {
      expect(names(cut(FeedStory(scene: 'card', side: 'away', data: {'type': 'red', 'drama': drama}), 30, 6.6, Tier.high)), 'coachReact');
    }
    expect(names(cut(FeedStory(scene: 'card', side: 'away', data: {'type': 'red', 'drama': 'tackle'}), 30, 6.6, Tier.high)), 'brawl,coachReact');
    expect(names(cut(FeedStory(scene: 'miss', data: {'how': 'over'}), 30, 5, Tier.mid)), 'meltdown');
    expect(names(cut(FeedStory(scene: 'miss', data: {'how': 'wide'}), 30, 5, Tier.mid)), 'coachReact');
    expect(names(cut(FeedStory(scene: 'whistle', data: {'name': 'halftime'}), 30, 3.6, Tier.high)), 'tunnel');
    expect(names(cut(FeedStory(scene: 'whistle', data: {'name': 'fulltime'}), 30, 3.6, Tier.high)), 'handshake,coachReact,coachReact');
    expect(names(cut(FeedStory(scene: 'var'), 30, 8.2, Tier.high)), 'coachReact,coachReact');
    expect(cut(FeedStory(), 30, 0, Tier.high), isEmpty, reason: 'no scene: no cutaway');
    expect('${cut(goal, 30, 6, Tier.high, seed: 9)}', '${cut(goal, 30, 6, Tier.high, seed: 9)}', reason: 'the same seed, the same cutaways');
  });

  LiveTick tick(Map<String, dynamic> moment, List<Map<String, dynamic>> events, {Map<String, dynamic>? voice}) =>
      LiveTick.fromJson({'tick': 30, 'minute': [30, 0], 'score': {'home': 1, 'away': 0}, 'events': events, 'moment': moment, 'voice': ?voice});
  const cast = <String, CastMember>{'9': (name: 'Salah', no: 11, side: 'home'), '4': (name: 'Saliba', no: 2, side: 'away'), '1': (name: 'Raya', no: 1, side: 'away'), '7': (name: 'Szoboszlai', no: 8, side: 'home')};
  const clubs = {'home': 'Liverpool', 'away': 'Arsenal'};

  test('the story: the server\'s moment becomes the scene, who is in it, and what is hidden until the ball arrives', () {
    final g = feedStory(tick({'kind': 'goal', 'ms': 12000}, [
      {'type': 'attack', 'team': 'home', 'shooter': 9, 'defender': 4, 'keeper': 1, 'quality': 'header', 'lane': 'left'},
      {'type': 'goal', 'team': 'home', 'scorer': 9, 'assist': 7},
    ]), cast: cast, clubs: clubs, seed: 5);
    expect((g.scene, g.side, g.goal, g.who, g.data['no'], g.data['passNo']), ('goal', 'home', true, 'Salah', '11', '8'));
    expect(g.pre!.head, 'عرضية', reason: 'a header: «a cross» until the ball arrives');
    expect(g.keyAt, 3.0);

    final red = feedStory(tick({'kind': 'red', 'ms': 9000, 'drama': 'brawl'}, [
      {'type': 'foul', 'team': 'away', 'player': 4, 'victim': 9},
      {'type': 'card', 'team': 'away', 'player': 4},
    ]), cast: cast, clubs: clubs, ar: false);
    expect((red.scene, red.data['type'], red.data['drama'], red.data['victimNo'], red.head), ('card', 'red', 'brawl', '11', 'Red card'));

    final over = feedStory(tick({'kind': 'miss', 'ms': 7000}, [{'type': 'attack', 'team': 'home', 'shooter': 9, 'result': 'wide'}], voice: {'how': 'over'}), cast: cast, clubs: clubs);
    expect((over.scene, over.data['how']), ('miss', 'over'), reason: 'where it went is the server\'s');

    final trap = feedStory(tick({'kind': 'offside', 'ms': 5000, 'drama': 'trap'}, [{'type': 'attack', 'team': 'home', 'receiver': 9}]), cast: cast, clubs: clubs);
    expect(trap.scene, 'trap');

    final brief = feedStory(tick({'kind': 'offside', 'ms': 2000, 'brief': true}, [{'type': 'attack', 'team': 'home', 'receiver': 9}]), cast: cast, clubs: clubs);
    expect(brief.scene, isNull, reason: 'a brief moment is only its card');

    final quiet = feedStory(tick({'kind': 'quiet', 'ms': 3000}, []), cast: cast, clubs: clubs);
    expect(quiet.scene, isNull);
  });

  test('the rain follows the match seed as the server decides it', () {
    expect([for (var s = 0; s < 12; s++) rainy(s)].where((x) => x), hasLength(2));
    expect(rainy(7), isTrue);
    expect(rainy(null), isFalse);
  });
}
