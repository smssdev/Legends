import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_background.dart';
import '../../core/sounds.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/cut.dart';
import '../../ui/widgets/game_icons.dart';
import '../../ui/widgets/stadium.dart';
import '../leagues/models.dart';
import 'club_data.dart';
import 'team_data.dart';
import '../leagues/shell.dart';

/// [Sprint 17 F1] The tactics (the web's TacticsPage): the plan, the tackling, the three sliders, the three lines, the
/// trap and the marking. Saved by itself a moment after each change (Sprint 27), and refused from the lock five minutes
/// before a match (the server's message). Only the plan, tackling, trap and marking ever reach the opponent.
class TacticsScreen extends ConsumerStatefulWidget {
  const TacticsScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  ConsumerState<TacticsScreen> createState() => _TacticsScreenState();
}

class _TacticsScreenState extends ConsumerState<TacticsScreen> {
  Tactics? _t;
  final Map<String, Object> _pending = {};
  Timer? _timer;
  late final TeamRepository _repo = ref.read(teamRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _repo; // taken now: a change still unsaved is sent on the way out, when ref can no longer be read
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_pending.isNotEmpty) unawaited(_repo.saveTactics(widget.leagueId, Map.of(_pending)).catchError((_) => const Tactics({})));
    super.dispose();
  }

  void _set(String key, Object v) {
    setState(() => _t = _t!.set(key, v));
    _pending[key] = v;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 700), _flush);
  }

  Future<void> _flush() async {
    if (_pending.isEmpty) return;
    final changes = Map.of(_pending);
    _pending.clear();
    try {
      await _repo.saveTactics(widget.leagueId, changes);
    } on ApiError catch (e) {
      if (mounted) showGlmToast(context, e.message, error: true);
      ref.invalidate(tacticsProvider(widget.leagueId));
      if (mounted) setState(() => _t = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      appBar: GameBar(title: Text(l.tactics)),
      body: GlmBackground(
        wide: true,
        child: AsyncView(
          value: ref.watch(tacticsProvider(widget.leagueId)),
          onRetry: () => ref.invalidate(tacticsProvider(widget.leagueId)),
          data: (loaded) {
            final t = _t ??= loaded;
            final l = L.of(context);
            final summary = ref.watch(clubSummaryProvider(widget.leagueId)).value;
            Widget gap(Widget w) => Padding(padding: const EdgeInsets.only(bottom: 12), child: w);
            Widget pair(Widget a, Widget b) => LayoutBuilder(builder: (context, box) => box.maxWidth < 560
                ? Column(children: [gap(a), gap(b)])
                : gap(IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)]))));
            String level(num v) => v < 40 ? l.low : v > 60 ? l.high : l.balancedWord;
            // [Sprint 46, the owner's screenshots] The tactics as the manager games set them: the next match first, then
            // each choice a card of its own, turned with its arrows and drawn (the plan on a little pitch, the lines on a
            // tall one), the three dials as sliders with their number, the trap and the marking.
            return ListView(padding: const EdgeInsets.fromLTRB(16, 10, 16, 24), children: [
              if (summary != null) gap(_NextCard(s: summary)),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(l.prepareTactics, textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24, shadows: [Shadow(color: Colors.black54, blurRadius: 6)])),
              ),
              pair(
                _Carousel(title: l.plan, values: const ['shots', 'counter', 'long', 'passing', 'wings'], value: '${t.values['plan']}',
                    label: (v) => {'passing': l.planPassing, 'counter': l.planCounter, 'long': l.planLong, 'wings': l.planWings, 'shots': l.planShots}[v]!,
                    picture: (v) => SizedBox(height: 120, child: CustomPaint(painter: _PlanArt(v), size: Size.infinite)), onChanged: (v) => _set('plan', v)),
                _Carousel(title: l.tackling, values: const [3, 2, 1, 0], value: (t.values['tackling'] as num).toInt(),
                    label: (v) => {0: l.tackle0, 1: l.tackle1, 2: l.tackle2, 3: l.tackle3}[v]!,
                    picture: (v) => SizedBox(height: 120, child: CustomPaint(painter: _TackleArt(v), size: Size.infinite)), onChanged: (v) => _set('tackling', v)),
              ),
              gap(_Lines(t: t, onSet: _set)),
              for (final (key, title, lo, hi) in [('pressing', l.pressing, l.low, l.high), ('style', l.style, l.defensive, l.attacking), ('tempo', l.tempo, l.calm, l.fast)])
                gap(_Dial(title: title, value: t.get<num>(key), word: level(t.get<num>(key)), low: lo, high: hi, onChanged: (v) => _set(key, v))),
              pair(
                _Carousel(title: l.marking, values: const ['zone', 'man'], value: '${t.values['marking']}', label: (v) => v == 'zone' ? l.markZone : l.markMan,
                    picture: (v) => SizedBox(height: 110, child: CustomPaint(painter: _MarkArt(v), size: Size.infinite)), onChanged: (v) => _set('marking', v)),
                _Carousel(title: l.trap, values: const [0, 1], value: (t.values['trap'] as num).toInt(), label: (v) => v == 1 ? l.yes : l.no,
                    picture: (v) => SizedBox(height: 110, child: CustomPaint(painter: _TrapArt(v == 1), size: Size.infinite)), onChanged: (v) => _set('trap', v)),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

const _cardFill = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [GlmArena.navyLight, GlmArena.navy]);
const _titleBlue = Color(0xFF7FC4FF);

/// The next match over the tactics: both crests and strengths, «VS», and the band of both formations under it.
class _NextCard extends StatelessWidget {
  const _NextCard({required this.s});

  final ClubSummary s;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final home = s.venue != 'away';
    Widget ring(int? v, bool mine) => Container(
          width: 58,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: GlmArena.navy, border: Border.all(color: const Color(0xFF55D6F2), width: 3)),
          child: Text(v == null ? '—' : '${v ~/ 100}', style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 26, color: Colors.white)),
        );
    Widget side(Side? c, bool mine) => Expanded(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ClubCrest(url: c?.crestUrl, name: c?.code ?? '', size: 62),
            const SizedBox(width: 10),
            Flexible(child: Text(c?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 28, color: Colors.white))),
          ]),
        );
    final (a, b) = home ? (s.club, s.next) : (s.next, s.club);
    final (sa, sb) = s.strength == null ? (null, null) : home ? (s.strength!.$1, s.strength!.$2) : (s.strength!.$2, s.strength!.$1);
    return ClipPath(
      clipper: ShapeBorderClipper(shape: GlmCut.shape(16), textDirection: Directionality.of(context)),
      child: Column(children: [
        SizedBox(
          height: 130,
          child: StadiumBackdrop(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                side(a, home),
                ring(sa, home),
                const SizedBox(width: 12),
                Text('VS', style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 52,
                    foreground: Paint()..shader = const LinearGradient(colors: [Color(0xFFFFE36E), Color(0xFFC08A0C)]).createShader(const Rect.fromLTWH(0, 0, 70, 50)))),
                const SizedBox(width: 12),
                ring(sb, !home),
                side(b, !home),
              ]),
            ),
          ),
        ),
        Container(
          color: GlmArena.navy,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(children: [
            const GameIcon(GameGlyph.lineup, size: 26),
            const SizedBox(width: 8),
            Text(home ? (s.formation ?? '') : '', style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 22, color: Colors.white)),
            const Spacer(),
            Text(l.nextMatchShort, style: const TextStyle(color: _titleBlue, fontWeight: FontWeight.w700, fontSize: 15)),
            const Spacer(),
            Text(home ? '' : (s.formation ?? ''), style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 22, color: Colors.white)),
            if (!home) ...[const SizedBox(width: 8), const GameIcon(GameGlyph.lineup, size: 26)],
          ]),
        ),
      ]),
    );
  }
}

/// A choice turned with its arrows (or a swipe): its title in blue, its value large, its picture, and a dot for each.
class _Carousel<T extends Object> extends StatelessWidget {
  const _Carousel({required this.title, required this.values, required this.value, required this.label, required this.picture, required this.onChanged});

  final String title;
  final List<T> values;
  final T value;
  final String Function(T) label;
  final Widget Function(T) picture;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final i = values.indexOf(value).clamp(0, values.length - 1);
    void step(int d) {
      GameSounds.play(Sfx.tap);
      onChanged(values[(i + d) % values.length]);
    }

    Widget arrow(IconData icon, int d) => Material(
          shape: const CircleBorder(),
          color: GlmArena.pillBlue,
          child: InkWell(customBorder: const CircleBorder(), onTap: () => step(d), child: SizedBox.square(dimension: 44, child: Icon(icon, color: Colors.white, size: 28))),
        );
    return GestureDetector(
      onHorizontalDragEnd: (e) => step((e.primaryVelocity ?? 0) < 0 ? 1 : -1),
      child: Container(
        decoration: ShapeDecoration(shape: GlmCut.shape(14), gradient: _cardFill),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(children: [
          Text(title, style: const TextStyle(color: _titleBlue, fontWeight: FontWeight.w700, fontSize: 17)),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(label(value), key: ValueKey(value), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24)),
          ),
          const SizedBox(height: 6),
          Row(children: [
            arrow(Icons.chevron_right_rounded, -1),
            Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: KeyedSubtree(key: ValueKey(value), child: picture(value)))),
            arrow(Icons.chevron_left_rounded, 1),
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var k = 0; k < values.length; k++)
              Container(width: 11, height: 11, margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: k == i ? Colors.white : Colors.white.withValues(alpha: .3))),
          ]),
        ]),
      ),
    );
  }
}

/// The three lines' orders, each turned with its arrows, and a tall pitch showing them as arrows.
class _Lines extends StatelessWidget {
  const _Lines({required this.t, required this.onSet});

  final Tactics t;
  final void Function(String key, Object v) onSet;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final rows = [
      ('att', l.groupAtt, const ['only', 'support', 'back'], {'back': l.attBack, 'support': l.attSupport, 'only': l.attOnly}, const Color(0xFF7FC4FF)),
      ('mid', l.groupMid, const ['push', 'stay', 'def'], {'def': l.midDef, 'stay': l.midStay, 'push': l.midPush}, const Color(0xFFFFB13D)),
      ('def', l.groupDef, const ['mid', 'fullbacks', 'stay'], {'stay': l.defStay, 'fullbacks': l.defFullbacks, 'mid': l.defMid}, const Color(0xFFFF7A3D)),
    ];
    return Container(
      decoration: ShapeDecoration(shape: GlmCut.shape(14), gradient: _cardFill),
      padding: const EdgeInsets.all(14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 3,
          child: Column(children: [
            Text(l.positioning, style: const TextStyle(color: _titleBlue, fontWeight: FontWeight.w700, fontSize: 17)),
            const SizedBox(height: 6),
            AspectRatio(aspectRatio: .82, child: CustomPaint(painter: _LinesArt('${t.values['att']}', '${t.values['mid']}', '${t.values['def']}'))),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: Column(children: [
            for (final (key, title, values, labels, colour) in rows) ...[
              const SizedBox(height: 8),
              Text(title, style: TextStyle(color: colour, fontWeight: FontWeight.w700, fontSize: 17)),
              Row(children: [
                _Arrow(Icons.chevron_right_rounded, () => onSet(key, values[(values.indexOf('${t.values[key]}') - 1) % values.length])),
                Expanded(child: Text(labels['${t.values[key]}'] ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20))),
                _Arrow(Icons.chevron_left_rounded, () => onSet(key, values[(values.indexOf('${t.values[key]}') + 1) % values.length])),
              ]),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (final v in values)
                  Container(width: 10, height: 10, margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: v == '${t.values[key]}' ? Colors.white : Colors.white.withValues(alpha: .3))),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow(this.icon, this.onTap);

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        shape: const CircleBorder(),
        color: GlmArena.pillBlue,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            GameSounds.play(Sfx.tap);
            onTap();
          },
          child: SizedBox.square(dimension: 44, child: Icon(icon, color: Colors.white, size: 28)),
        ),
      );
}

/// A dial as the manager games show it: its title, its word, its number in a black box and the slider.
class _Dial extends StatelessWidget {
  const _Dial({required this.title, required this.value, required this.word, required this.low, required this.high, required this.onChanged});

  final String title, word, low, high;
  final num value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        decoration: ShapeDecoration(shape: GlmCut.shape(14), gradient: _cardFill),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Column(children: [
          Text(title, style: const TextStyle(color: _titleBlue, fontWeight: FontWeight.w700, fontSize: 17)),
          Text(word, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
          Row(children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 8,
                  activeTrackColor: GlmArena.pillBlue,
                  inactiveTrackColor: Colors.black.withValues(alpha: .45),
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                ),
                child: Slider(value: value.toDouble(), min: 0, max: 100, divisions: 100, onChanged: (v) => onChanged(v.round())),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 54,
              height: 48,
              alignment: Alignment.center,
              color: Colors.black,
              child: Text('${value.round()}', style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 26, color: Colors.white)),
            ),
          ]),
          Row(children: [
            Text(low, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const Spacer(),
            Text(high, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(width: 66),
          ]),
        ]),
      );
}

/// A little pitch in perspective, our own drawing, its two goals; the art's arrows go on top.
void _miniPitch(Canvas c, Size s, Rect f) {
  final grass = Path()..moveTo(f.left + f.width * .08, f.top)..lineTo(f.right - f.width * .08, f.top)..lineTo(f.right, f.bottom)..lineTo(f.left, f.bottom)..close();
  c.drawPath(grass.shift(Offset(0, f.height * .1)), Paint()..color = const Color(0xFF6E431B));
  c.drawPath(grass, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2FA046), Color(0xFF1E7A34)]).createShader(f));
  final line = Paint()..color = Colors.white.withValues(alpha: .7)..style = PaintingStyle.stroke..strokeWidth = 1.2;
  c.drawPath(grass, line);
  c.drawLine(Offset(f.center.dx, f.top), Offset(f.center.dx, f.bottom), line);
  c.drawOval(Rect.fromCenter(center: f.center, width: f.width * .14, height: f.height * .42), line);
  for (final left in [true, false]) {
    final x = left ? f.left + f.width * .06 : f.right - f.width * .06, d = left ? 1.0 : -1.0;
    c.drawRect(Rect.fromPoints(Offset(x, f.top + f.height * .25), Offset(x + d * f.width * .1, f.bottom - f.height * .25)), line);
  }
}

void _arrowLine(Canvas c, List<Offset> pts, Color color, {double width = 4}) {
  final path = Path()..moveTo(pts.first.dx, pts.first.dy);
  if (pts.length == 3) {
    path.quadraticBezierTo(pts[1].dx, pts[1].dy, pts[2].dx, pts[2].dy);
  } else {
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
  }
  c.drawPath(path, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = width..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
  final end = pts.last, before = pts.length == 3 ? pts[1] : pts[pts.length - 2];
  final a = math.atan2(end.dy - before.dy, end.dx - before.dx);
  c.drawPath(Path()..moveTo(end.dx + math.cos(a) * width * 2, end.dy + math.sin(a) * width * 2)..lineTo(end.dx + math.cos(a + 2.4) * width * 2.4, end.dy + math.sin(a + 2.4) * width * 2.4)..lineTo(end.dx + math.cos(a - 2.4) * width * 2.4, end.dy + math.sin(a - 2.4) * width * 2.4)..close(), Paint()..color = color);
}

/// The plan drawn on its pitch (attacking toward the reading start): short passes weaving, a counter's long ball after
/// the short ones, the long ball's arc, both wings, shots from distance.
class _PlanArt extends CustomPainter {
  _PlanArt(this.plan);

  final String plan;

  @override
  void paint(Canvas c, Size s) {
    final f = Rect.fromLTWH(s.width * .04, s.height * .22, s.width * .92, s.height * .62);
    _miniPitch(c, s, f);
    const red = Color(0xFFE53935), blue = Color(0xFF2B7ED3);
    Offset at(double u, double v) => Offset(f.left + f.width * u, f.top + f.height * v);
    switch (plan) {
      case 'passing':
        _arrowLine(c, [at(.85, .5), at(.75, .5), at(.68, .3), at(.6, .65), at(.52, .35), at(.44, .7), at(.36, .45), at(.18, .5)], red, width: 3);
      case 'counter':
        _arrowLine(c, [at(.82, .7), at(.62, .75)], blue, width: 3);
        _arrowLine(c, [at(.6, .72), at(.4, .68)], blue, width: 3);
        _arrowLine(c, [at(.78, .4), at(.5, -.3), at(.22, .4)], red);
      case 'long':
        _arrowLine(c, [at(.8, .55), at(.5, -.5), at(.2, .55)], red, width: 5);
      case 'wings':
        _arrowLine(c, [at(.72, .12), at(.25, .12)], red);
        _arrowLine(c, [at(.72, .88), at(.25, .88)], red);
      default:
        for (final (u, v) in [(.42, .3), (.44, .5), (.42, .72)]) {
          _arrowLine(c, [at(u, v), at(u - .18, v + .02)], red, width: 3);
          c.drawCircle(at(u + .03, v), 5, Paint()..color = Colors.white);
        }
    }
  }

  @override
  bool shouldRepaint(_PlanArt old) => old.plan != plan;
}

/// How hard they tackle: a boot meeting the ball, the cards it may bring (none, a yellow, a yellow and a red).
class _TackleArt extends CustomPainter {
  _TackleArt(this.level);

  final int level;

  @override
  void paint(Canvas c, Size s) {
    final mid = Offset(s.width / 2, s.height * .55);
    // The boot's studs and sole, sliding in harder with each level.
    final boot = Path()
      ..moveTo(mid.dx - 60, mid.dy - 6)
      ..quadraticBezierTo(mid.dx - 20, mid.dy - 30, mid.dx + 14, mid.dy - 14)
      ..lineTo(mid.dx + 24, mid.dy + 4)
      ..lineTo(mid.dx - 60, mid.dy + 10)
      ..close();
    c.save();
    c.translate(-level * 8.0, 0);
    c.rotate(-.06 * level);
    c.drawPath(boot, Paint()..color = const Color(0xFF1B1B1B));
    for (var i = 0; i < 4; i++) {
      c.drawRect(Rect.fromLTWH(mid.dx - 52 + i * 18.0, mid.dy + 10, 6, 6), Paint()..color = const Color(0xFFCFD8E6));
    }
    c.restore();
    c.drawCircle(Offset(mid.dx + 44, mid.dy - 2), 14, Paint()..color = Colors.white);
    c.drawCircle(Offset(mid.dx + 44, mid.dy - 2), 5, Paint()..color = const Color(0xFF1C1C1C));
    // Speed lines for the keener levels.
    for (var i = 0; i < level; i++) {
      c.drawLine(Offset(mid.dx - 96 - i * 6.0, mid.dy - 14 + i * 9.0), Offset(mid.dx - 72, mid.dy - 14 + i * 9.0), Paint()..color = Colors.white38..strokeWidth = 3..strokeCap = StrokeCap.round);
    }
    final cards = [if (level >= 2) const Color(0xFFFFD600), if (level >= 3) const Color(0xFFE53935)];
    for (final (i, col) in cards.indexed) {
      c.save();
      c.translate(s.width / 2 + 70 + i * 22.0, s.height * .22);
      c.rotate(.15 + i * .12);
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-12, -17, 24, 34), const Radius.circular(3)), Paint()..color = col);
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_TackleArt old) => old.level != level;
}

/// The three lines on a tall pitch (attacking upward), each order an arrow: the forwards back, supporting or only up;
/// the midfield back, holding or pushing on; the defence holding, the full-backs going up, or stepping into midfield.
class _LinesArt extends CustomPainter {
  _LinesArt(this.att, this.mid, this.def);

  final String att, mid, def;

  @override
  void paint(Canvas c, Size s) {
    final r = RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(12));
    c.drawRRect(r, Paint()..color = const Color(0xFF4CAF35));
    c.save();
    c.clipRRect(r);
    for (var i = 0; i < 8; i += 2) {
      c.drawRect(Rect.fromLTWH(0, s.height * i / 8, s.width, s.height / 8), Paint()..color = Colors.white.withValues(alpha: .05));
    }
    final line = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3;
    c.drawLine(Offset(0, s.height / 2), Offset(s.width, s.height / 2), line);
    c.drawCircle(Offset(s.width / 2, s.height / 2), s.width * .14, line);
    for (final top in [true, false]) {
      final y = top ? 0.0 : s.height;
      final d = top ? 1.0 : -1.0;
      c.drawRect(Rect.fromPoints(Offset(s.width * .24, y), Offset(s.width * .76, y + d * s.height * .16)), line);
      c.drawRect(Rect.fromPoints(Offset(s.width * .38, y), Offset(s.width * .62, y + d * s.height * .06)), line);
    }
    c.restore();
    Offset at(double u, double v) => Offset(s.width * u, s.height * v);
    const blue = Color(0xFF4FA3FF), orange = Color(0xFFFFB13D), red = Color(0xFFFF6A2B);
    void cross(Offset o, Color col) {
      for (final d in [const Offset(1, 0), const Offset(0, 1)]) {
        _arrowLine(c, [o, o + d * 26], col, width: 4);
        _arrowLine(c, [o, o - d * 26], col, width: 4);
      }
    }

    switch (att) {
      case 'only':
        _arrowLine(c, [at(.5, .3), at(.5, .14)], blue, width: 7);
      case 'support':
        _arrowLine(c, [at(.5, .14), at(.5, .3)], blue, width: 7);
      default:
        _arrowLine(c, [at(.5, .12), at(.5, .36)], blue, width: 7);
    }
    switch (mid) {
      case 'push':
        _arrowLine(c, [at(.46, .6), at(.36, .5), at(.38, .38)], orange, width: 7);
        _arrowLine(c, [at(.54, .6), at(.64, .5), at(.62, .38)], orange, width: 7);
      case 'def':
        _arrowLine(c, [at(.3, .48), at(.3, .62)], orange, width: 6);
        _arrowLine(c, [at(.7, .48), at(.7, .62)], orange, width: 6);
      default:
        cross(at(.24, .5), orange);
        cross(at(.76, .5), orange);
    }
    switch (def) {
      case 'fullbacks':
        _arrowLine(c, [at(.16, .9), at(.16, .66)], red, width: 7);
        _arrowLine(c, [at(.84, .9), at(.84, .66)], red, width: 7);
      case 'mid':
        _arrowLine(c, [at(.5, .88), at(.5, .66)], red, width: 7);
      default:
        cross(at(.5, .8), red);
    }
  }

  @override
  bool shouldRepaint(_LinesArt old) => old.att != att || old.mid != mid || old.def != def;
}

/// The marking: an area for each defender (zone), or a line from each to his man.
class _MarkArt extends CustomPainter {
  _MarkArt(this.mode);

  final String mode;

  @override
  void paint(Canvas c, Size s) {
    final f = Rect.fromLTWH(s.width * .1, s.height * .2, s.width * .8, s.height * .66);
    _miniPitch(c, s, f);
    Offset at(double u, double v) => Offset(f.left + f.width * u, f.top + f.height * v);
    for (var i = 0; i < 4; i++) {
      final d = at(.3, .14 + i * .24), a = at(.42, .2 + i * .22);
      if (mode == 'zone') {
        c.drawOval(Rect.fromCenter(center: d, width: f.width * .22, height: f.height * .22), Paint()..color = const Color(0xFF4FA3FF).withValues(alpha: .35));
      } else {
        c.drawLine(d, a, Paint()..color = const Color(0xFFFFE36E)..strokeWidth = 2.5);
      }
      c.drawCircle(d, 6, Paint()..color = const Color(0xFF2B7ED3));
      c.drawCircle(a, 6, Paint()..color = const Color(0xFFE53935));
    }
  }

  @override
  bool shouldRepaint(_MarkArt old) => old.mode != mode;
}

/// The offside trap: the back line stepping up together and the assistant's flag up (or the line holding).
class _TrapArt extends CustomPainter {
  _TrapArt(this.on);

  final bool on;

  @override
  void paint(Canvas c, Size s) {
    final f = Rect.fromLTWH(s.width * .1, s.height * .2, s.width * .8, s.height * .66);
    _miniPitch(c, s, f);
    Offset at(double u, double v) => Offset(f.left + f.width * u, f.top + f.height * v);
    final x = on ? .44 : .3;
    if (on) c.drawLine(at(x, .02), at(x, .98), Paint()..color = const Color(0xFFFFD600)..strokeWidth = 2);
    for (var i = 0; i < 4; i++) {
      final p = at(x, .14 + i * .24);
      if (on) _arrowLine(c, [at(.3, .14 + i * .24), p], const Color(0xFF7FC4FF), width: 2.5);
      c.drawCircle(p, 6, Paint()..color = const Color(0xFF2B7ED3));
    }
    c.drawCircle(at(.4, .5), 6, Paint()..color = const Color(0xFFE53935));
    // The flag.
    final pole = at(.52, -.1);
    c.drawLine(pole, pole + const Offset(0, -26), Paint()..color = Colors.white..strokeWidth = 2);
    c.drawRect(Rect.fromLTWH(pole.dx, pole.dy - 26, 16, on ? 11 : 0), Paint()..color = const Color(0xFFFF6D00));
  }

  @override
  bool shouldRepaint(_TrapArt old) => old.on != on;
}
