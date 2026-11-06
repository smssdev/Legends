import '../match_data.dart';

/// [Sprint 44 A2] What one minute becomes on the app's broadcast, as on the web (web/src/match/feed/story.ts): the scene
/// to play, its side and who is in it, the lower third's three lines, and what it says before the key moment so the
/// result is not told before the ball gets there. The scene's kind and its drama are the server's (tick.moment); this
/// only reads them. The commentary lines are the server's too (each event's text, in the feed).

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

/// The seeded random of the web's story (mulberry32), so a minute's scene varies the same way everywhere.
double Function() seededRandom(int seed) {
  var a = seed & 0xFFFFFFFF;
  int imul(int x, int y) => (x * y) & 0xFFFFFFFF;
  return () {
    a = (a + 0x6d2b79f5) & 0xFFFFFFFF;
    var t = a;
    t = imul(t ^ (t >> 15), t | 1);
    t ^= (t + imul(t ^ (t >> 7), t | 61)) & 0xFFFFFFFF;
    return ((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296;
  };
}

/// The minute's story. [cast]: each player id's name, number and side; [clubs]: each side's name; [mine]: the side this
/// screen manages, or null; [ar]: the lower third in Arabic.
FeedStory feedStory(LiveTick tick, {required Map<String, CastMember> cast, required Map<String, String> clubs, int? seed, String? mine, bool ar = true}) {
  String tr(String a, String e) => ar ? a : e;
  final r = seededRandom((seed ?? 1) * 31 + tick.tick * 977);
  int vary() => (r() * 1e9).floor();
  Map<String, dynamic>? first(String type) => tick.events.where((e) => e.type == type).map((e) => e.raw).firstOrNull;
  String nm(Object? id) => id == null ? '' : cast['$id']?.name ?? '';
  String no(Object? id) => id == null ? '' : '${cast['$id']?.no ?? ''}';
  String club(String side) => clubs[side] ?? '';
  String other(String s) => s == 'home' ? 'away' : 'home';

  final kind = tick.moment?.kind ?? 'quiet';
  final drama = tick.moment?.drama;
  final attack = first('attack'), goal = first('goal'), card = first('card'), foul = first('foul');
  final pen = first('penalty'), fk = first('free_kick'), corner = first('corner'), sub = first('sub'), injury = first('injury');
  final period = first('period'), stoppage = first('stoppage');
  final action = tick.events.where((e) => e.type == 'action' && ['tactics', 'formation'].contains((e.raw['action'] as Map?)?['type'])).map((e) => e.raw).firstOrNull;

  FeedStory out = FeedStory();
  FeedStory make(String scene, String side, Map<String, Object?> data, String head, String who, String sub, {({String head, String who, String sub})? pre, bool goal = false}) =>
      FeedStory(scene: scene, side: side, data: {'side': side, ...data}, head: head, who: who, sub: sub, pre: pre, goal: goal);

  if (kind == 'goal' && goal != null) {
    final s = '${goal['team']}', header = attack?['quality'] == 'header';
    out = make('goal', s, {
      'drama': drama, 'no': no(goal['scorer']), 'passNo': goal['assist'] == null ? '' : no(goal['assist']), 'defNo': no(attack?['defender']),
      'lane': attack?['lane'], 'quality': attack?['quality'], 'v': vary(),
    }, tr('هدف!', 'GOAL!'), nm(goal['scorer']), goal['assist'] != null ? tr('صناعة ${nm(goal['assist'])}', 'Assist ${nm(goal['assist'])}') : club(s),
        pre: (head: header ? tr('عرضية', 'A cross') : tr('هجمة خطيرة', 'Danger'), who: nm(goal['scorer']), sub: club(s)), goal: true);
  } else if ((kind == 'penalty' || kind == 'free_kick') && (pen ?? fk) != null) {
    final sp = (pen ?? fk)!, s = '${sp['team']}', scored = goal != null, isPen = kind == 'penalty';
    final result = scored ? 'goal' : sp['keeper'] != null ? 'save' : 'miss';
    out = make(isPen ? 'penalty' : 'freekick', s, {'no': no(sp['taker']), 'scored': scored, 'saved': result == 'save', 'v': vary()},
        scored ? tr('هدف!', 'GOAL!') : isPen ? tr('ركلة جزاء', 'Penalty') : tr('ضربة حرة', 'Free kick'), nm(sp['taker']),
        scored
            ? (isPen ? tr('ركلة جزاء', 'From the spot') : tr('ضربة حرة مباشرة', 'Direct free kick'))
            : result == 'save'
                ? tr('تصدى ${nm(sp['keeper'])}', 'Saved by ${nm(sp['keeper'])}')
                : tr('خارج المرمى', 'Off target'),
        pre: (head: isPen ? tr('ركلة جزاء', 'Penalty') : tr('ضربة حرة', 'Free kick'), who: nm(sp['taker']), sub: tr('المنفذ يستعد... والجميع ينتظر', 'The taker steps up...')),
        goal: scored);
  } else if ((kind == 'red' || kind == 'yellow') && card != null) {
    final s = '${card['team']}', red = kind == 'red';
    final victim = foul != null && foul['team'] == s ? foul['victim'] : null;
    out = make('card', s, {
      'no': no(card['player']), 'victimNo': no(victim), 'type': red ? 'red' : 'yellow', 'second': card['second_yellow'] == true, 'drama': drama ?? 'tackle', 'v': vary(),
    }, red ? tr('بطاقة حمراء', 'Red card') : tr('بطاقة صفراء', 'Yellow card'), nm(card['player']), card['second_yellow'] == true ? tr('الإنذار الثاني', 'Second yellow') : club(s),
        pre: (head: tr('خطأ', 'Foul'), who: nm(card['player']), sub: tr('الحكم يقترب...', 'The referee comes over...')));
  } else if (kind == 'foul' && foul != null) {
    final s = '${foul['team']}', dive = drama == 'dive';
    out = make('foul', s, {'no': no(foul['player']), 'victimNo': no(foul['victim']), 'drama': dive ? 'dive' : 'tackle', 'v': vary()},
        dive ? tr('سقوط مثير!', 'What a fall!') : tr('خطأ', 'Foul'), nm(foul['victim']), dive ? tr('والحكم يحتسب خطأ', 'and the referee gives it') : tr('عرقلة من ${nm(foul['player'])}', 'Brought down by ${nm(foul['player'])}'));
  } else if (kind == 'save' && attack != null) {
    final s = '${attack['team']}';
    out = make('save', s, {
      'drama': drama, 'no': no(attack['shooter']), 'passNo': attack['creator'] != attack['shooter'] ? no(attack['creator']) : '', 'defNo': no(attack['defender']),
      'lane': attack['lane'], 'quality': attack['quality'], 'corner': attack['result'] == 'corner', 'v': vary(),
    }, tr('تصدٍّ رائع', 'Great save'), nm(attack['keeper']).isEmpty ? tr('الحارس', 'The keeper') : nm(attack['keeper']), tr('أمام ${nm(attack['shooter'])}', 'from ${nm(attack['shooter'])}'),
        pre: (head: tr('تسديدة', 'A shot'), who: nm(attack['shooter']), sub: club(s)));
  } else if (kind == 'miss' && attack != null) {
    final s = '${attack['team']}', blocked = attack['result'] == 'blocked';
    final how = blocked ? null : tick.how ?? ['wide', 'wide', 'over', 'post'][(r() * 4).floor()];
    final look = {'passNo': attack['creator'] != attack['shooter'] ? no(attack['creator']) : '', 'lane': attack['lane'], 'quality': attack['quality'], 'v': vary()};
    final pre = (head: tr('تسديدة', 'A shot'), who: nm(attack['shooter']), sub: club(s));
    if (blocked && drama == 'clearance') {
      out = make('clearance', s, {'no': no(attack['shooter']), 'defNo': no(attack['defender']), ...look}, tr('أنقذها من على الخط!', 'Cleared off the line!'),
          nm(attack['defender']).isEmpty ? club(other(s)) : nm(attack['defender']), tr('أمام ${nm(attack['shooter'])}', 'from ${nm(attack['shooter'])}'), pre: pre);
    } else if (blocked) {
      out = make('blocked', s, {'no': no(attack['shooter']), 'defNo': no(attack['defender']), ...look}, tr('صدّها الدفاع', 'Blocked'), nm(attack['shooter']),
          nm(attack['defender']).isEmpty ? club(other(s)) : tr('تدخل ${nm(attack['defender'])}', 'by ${nm(attack['defender'])}'), pre: pre);
    } else {
      out = make('miss', s, {'no': no(attack['shooter']), 'defNo': no(attack['defender']), 'how': how, ...look}, how == 'post' ? tr('القائم!', 'Off the post!') : tr('فرصة ضائعة', 'So close'),
          nm(attack['shooter']), how == 'over' ? tr('فوق العارضة', 'Over the bar') : how == 'post' ? tr('ارتطمت بالقائم', 'It hits the post') : tr('بجانب القائم', 'Just wide'), pre: pre);
    }
  } else if (kind == 'var' && attack != null) {
    final s = '${attack['team']}', who = attack['shooter'] ?? attack['receiver'], reason = tick.moment?.varReason == 'foul' ? 'foul' : 'offside';
    out = make('var', s, {'no': no(who), 'passNo': attack['creator'] != who ? no(attack['creator']) : '', 'defNo': no(attack['defender']), 'reason': reason, 'v': vary()},
        tr('هدف ملغى', 'No goal'), nm(who), reason == 'offside' ? tr('تسلل بعد العودة للفار', 'Offside, after VAR') : tr('خطأ قبل الهدف بعد العودة للفار', 'A foul first, after VAR'),
        pre: (head: tr('هدف!', 'GOAL!'), who: nm(who), sub: club(s)));
  } else if (kind == 'offside' && attack != null) {
    final s = '${attack['team']}', who = attack['receiver'] ?? attack['shooter'], trap = drama == 'trap';
    out = make(trap ? 'trap' : 'offside', s, {'no': no(who)}, trap ? tr('مصيدة التسلل!', 'The offside trap!') : tr('تسلل', 'Offside'), nm(who), club(s),
        pre: (head: tr('كرة خلف الدفاع', 'In behind'), who: nm(who), sub: club(s)));
  } else if (kind == 'corner' && corner != null) {
    final s = '${corner['team']}', won = corner['won'] != false, header = attack?['shooter'];
    out = make('corner', s, {'no': no(header ?? corner['taker']), 'claim': !won, 'v': vary()}, tr('ركنية', 'Corner'), nm(won && header != null ? header : corner['taker']),
        won ? tr('رأسية فوق العارضة', 'Headed over') : tr('الحارس يمسك الكرة', 'The keeper claims it'), pre: (head: tr('ركنية', 'Corner'), who: nm(corner['taker']), sub: club(s)));
  } else if (kind == 'sub' && sub != null) {
    final s = '${sub['team']}';
    out = make('sub', s, {'inNo': no(sub['in']), 'outNo': no(sub['out'])}, tr('تبديل', 'Substitution'), '${nm(sub['in'])} ⇄ ${nm(sub['out'])}', club(s));
  } else if (kind == 'injury' && injury != null) {
    final s = '${injury['team']}';
    out = make('injury', s, {'no': no(injury['player'])}, tr('إصابة', 'Injury'), nm(injury['player']), club(s));
  } else if (kind == 'coach' && action != null) {
    // The other side's instructions stay private: only «new instructions» (CLAUDE.md, privacy in a match).
    final s = '${action['team']}', rant = drama == 'rant';
    final tactic = mine == s || mine == null ? tr('تعليمات جديدة', 'New instructions') : tr('تعليمات جديدة', 'New instructions');
    out = make(rant ? 'rant' : 'coach', s, {}, rant ? tr('المدرب غاضب!', 'The coach is furious!') : tr('تعليمات المدرب', 'The coach steps in'), tr('مدرب ${club(s)}', '${club(s)} coach'), tactic);
  } else if (kind == 'whistle' && period != null) {
    final name = '${period['name']}';
    final big = {'halftime': tr('استراحة', 'Half time'), 'fulltime': tr('النهاية', 'Full time'), 'extra_time': tr('وقت إضافي', 'Extra time'), 'extra_time_half': tr('استراحة قصيرة', 'Short break'), 'penalties': tr('ركلات الترجيح', 'Penalties')}[name] ?? '';
    int stat(String side, String k) => tick.teams?[side]?.stats[k] ?? 0;
    final rows = [
      for (final (label, k) in [(tr('الهجمات', 'Attacks'), 'attacks'), (tr('التسديدات', 'Shots'), 'shots'), (tr('على المرمى', 'On target'), 'on_target'), (tr('الركنيات', 'Corners'), 'corners')])
        (label, stat('home', k), stat('away', k)),
    ];
    out = make('whistle', 'home', {'name': name, 'big': big, 'home': tick.score.$1, 'away': tick.score.$2, 'stats': rows}, big, '', '${club('home')} ${tick.score.$1} - ${tick.score.$2} ${club('away')}');
  } else if (kind == 'slip' && attack != null) {
    final s = '${attack['team']}';
    out = make('slip', s, {'no': no(attack['carrier']), 'defNo': no(attack['defender'])}, tr('انزلاق!', 'A slip!'), nm(attack['carrier']),
        nm(attack['defender']).isEmpty ? club(other(s)) : tr('والكرة لـ${nm(attack['defender'])}', 'and ${nm(attack['defender'])} takes it'));
  } else if (kind == 'stoppage' && stoppage != null) {
    out = make('board', 'home', {'plus': stoppage['added']}, tr('الوقت بدل الضائع', 'Added time'), '+${stoppage['added']}', tr('دقائق', 'minutes'));
  }
  // [X41] A small moment on the broadcast (tick.moment.brief): no scene, only its card in the feed.
  if (tick.moment?.brief == true) return FeedStory();
  return out;
}

/// The rain, from the match's seed as the server decides it (MomentClock::rainy: one match in six). Keep them in step.
bool rainy(int? seed) => seed != null && seed % 6 == 1;
