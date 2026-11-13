import '../../../ui/tokens.g.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../core/sounds.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/cut.dart';
import '../../../ui/widgets/motion.dart';
import 'art.dart';
import 'clips.dart';
import 'director.dart';
import 'story.dart';
import '../../../l10n/app_localizations.dart';

/// [Sprint 44 C1] One minute to play on the broadcast: its story, how long the scene runs within the minute, and the
/// director's cutaways after it. Built by [BroadcastPlay.of] as the web's MatchFeed.vue play() builds its plan.
class BroadcastPlay {
  BroadcastPlay({required this.tick, required this.story, required this.sceneT, required this.cuts});

  /// [total]: the minute's length on the broadcast (tick.moment.ms) in seconds.
  factory BroadcastPlay.of(
    int tick,
    FeedStory s, {
    required double total,
    required Map<String, String> moods,
    required Tier tier,
    Map<String, String>? looks,
    int seed = 1,
  }) {
    final nominal = s.length;
    // The scene takes most of the minute; at the broadcast's fixed pace (a minute of 3.4 s or less) up to nine tenths.
    final sceneT = math.min(nominal, total * (total <= 3.4 ? .9 : .72));
    return BroadcastPlay(
      tick: tick,
      story: s,
      sceneT: sceneT,
      cuts: director(s, tick: tick, moods: moods, total: total, sceneT: sceneT, tier: tier, looks: looks, seed: seed),
    );
  }

  final int tick;
  final FeedStory story;
  final double sceneT;
  final List<Cut> cuts;

  /// The scene's clock runs a little fast when the minute is shorter than the scene.
  double get rate => story.length / sceneT;
  double get keyAt => story.keyAt / rate;
  double get length => sceneT + cuts.fold(0.0, (a, c) => a + c.dur);
}

/// The broadcast over the pitch: while a minute's scene and its cutaways play they cover [child] (the light pitch, or
/// the studio before kick-off); then the pitch again. The lower third holds the result back until the key moment, and
/// [onKey] tells the page to reveal it (the score, the event in the feed). A tap skips what is playing.
class BroadcastStage extends StatefulWidget {
  const BroadcastStage({super.key, required this.child, required this.look, required this.queue, required this.onKey, this.studio});

  final Widget child;
  final ClipLook look;

  /// The minutes waiting to play, oldest first; the stage takes from it.
  final List<BroadcastPlay> queue;

  /// The minute's key moment has come (or it was skipped): its result may be shown.
  final void Function(int tick) onKey;

  /// The studio between moments, when there is nothing on the pitch yet (score and clock on its LED wall).
  final ({String score, String clock})? studio;

  @override
  State<BroadcastStage> createState() => _BroadcastStageState();
}

class _BroadcastStageState extends State<BroadcastStage> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  BroadcastPlay? _play;
  Duration _start = Duration.zero;
  double _t = 0, _studioT = 0;
  bool _keyed = false;
  final Set<String> _fired = {};

  @override
  void initState() {
    super.initState();
    _wake();
  }

  @override
  void didUpdateWidget(BroadcastStage old) {
    super.didUpdateWidget(old);
    _wake();
  }

  /// Runs while there is something to play (or the studio to animate); stands still otherwise. With the motion off
  /// (less motion asked, the widget tests) the minutes are told at once, without their scenes.
  void _wake() {
    final still = !Ambient.on || (WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations);
    if (still) {
      if (widget.queue.isNotEmpty) {
        final ticks = [for (final p in widget.queue) p.tick];
        widget.queue.clear();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          for (final t in ticks) {
            widget.onKey(t);
          }
        });
      }
      return;
    }
    if (!_ticker.isActive && (widget.queue.isNotEmpty || widget.studio != null)) _ticker.start();
  }

  @override
  void dispose() {
    final p = _play;
    if (p != null && !_keyed) widget.onKey(p.tick);
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration now) {
    if (_play == null && widget.queue.isNotEmpty) {
      // Behind (a gap, a slow phone): only the latest minute plays, the others are told at once.
      while (widget.queue.length > 1) {
        widget.onKey(widget.queue.removeAt(0).tick);
      }
      _play = widget.queue.removeAt(0);
      _start = now;
      _keyed = false;
      _fired.clear();
    }
    final p = _play;
    if (p == null) {
      if (widget.studio != null) {
        setState(() => _studioT = now.inMicroseconds / 1e6);
      } else {
        _ticker.stop();
      }
      return;
    }
    _t = (now - _start).inMicroseconds / 1e6;
    _cues(p);
    if (_t >= p.length) {
      _end();
    } else {
      setState(() {});
    }
  }

  void _end() {
    final p = _play;
    if (p != null && !_keyed) widget.onKey(p.tick);
    setState(() => _play = null);
  }

  /// The sounds and the phone's buzz at their moments: the kick, the net and the roar, the groan, the whistle.
  void _cues(BroadcastPlay p) {
    void at(String key, double when, void Function() fn) {
      if (_t >= when && _fired.add(key)) fn();
    }

    final s = p.story;
    final key = p.keyAt;
    at('key', key, () {
      _keyed = true;
      widget.onKey(p.tick);
    });
    switch (s.scene) {
      case 'goal' || 'save' || 'miss' || 'blocked' || 'clearance' || 'var':
        at('kick', key - .4 / p.rate, () => GameSounds.play(Sfx.kick));
      case 'penalty':
        at('kick', key - .05 / p.rate, () => GameSounds.play(Sfx.kick));
      case 'freekick':
        at('kick', key - .35 / p.rate, () => GameSounds.play(Sfx.kick));
      case 'card' || 'foul' || 'offside' || 'trap' || 'whistle':
        at('whistle', s.scene == 'card' ? key - 1.2 / p.rate : key, () => GameSounds.play(Sfx.whistle));
    }
    if (s.goal) {
      at('roar', key, () {
        GameSounds.play(Sfx.roar);
        HapticFeedback.heavyImpact();
      });
      at('buzz', key + .18, HapticFeedback.heavyImpact);
    } else if (['miss', 'save', 'clearance', 'blocked'].contains(s.scene) ||
        (['penalty', 'freekick'].contains(s.scene) && s.data['scored'] != true)) {
      at('ooh', key, () => GameSounds.play(Sfx.ooh));
    } else if (s.scene == 'card' && s.data['type'] == 'red') {
      at('red', key, HapticFeedback.mediumImpact);
    } else if (s.scene == 'var') {
      at('var', key, HapticFeedback.mediumImpact);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _play;
    if (p == null) {
      final studio = widget.studio;
      if (studio == null) return widget.child;
      return CutClip(
        child: CustomPaint(
          painter: ClipPainter(
            scene: 'studio',
            data: {'score': studio.score, 'clock': studio.clock},
            side: 'home',
            u: _studioT,
            look: widget.look,
          ),
          child: const SizedBox.expand(),
        ),
      );
    }
    // Which picture now: the scene, or one of the cutaways after it.
    var scene = p.story.scene!, data = p.story.data, side = p.story.side, u = _t * p.rate;
    if (_t >= p.sceneT) {
      var from = p.sceneT;
      for (final c in p.cuts) {
        if (_t < from + c.dur) {
          scene = c.name;
          data = c.data;
          side = '${c.data['side'] ?? side}';
          u = _t - from;
          break;
        }
        from += c.dur;
      }
    }
    final inScene = _t < p.sceneT;
    final revealed = _t >= p.keyAt;
    final s = p.story;
    final third = !inScene || revealed || s.pre == null ? (head: s.head, who: s.who, sub: s.sub) : s.pre!;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return GestureDetector(
      onTap: _end,
      child: CutClip(
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: CustomPaint(
                painter: ClipPainter(scene: scene, data: data, side: side, u: u, look: widget.look),
              ),
            ),
            // A goal: the banner at the key moment, and the gold confetti.
            if (s.goal && revealed) _GoalBanner(t: _t - p.keyAt, who: s.who, ar: ar),
            if (s.goal && revealed)
              IgnorePointer(
                child: CustomPaint(
                  painter: _Confetti(t: _t - p.keyAt, gold: widget.look.gold, kit: widget.look.shirt(s.side)),
                ),
              ),
            // The lower third, through the scene and its cutaways.
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: _LowerThird(
                head: third.head,
                who: third.who,
                sub: third.sub,
                kit: widget.look.shirt(s.side),
                alert: s.goal && revealed,
              ),
            ),
            Positioned(top: 8, right: 10, child: _Tag(scene == p.story.scene ? 'LIVE' : 'GLM TV', live: scene == p.story.scene)),
          ],
        ),
      ),
    );
  }
}

/// The lower third: the moment on a slab in the Legend Cut, in the club's colour, the player and a line under.
class _LowerThird extends StatelessWidget {
  const _LowerThird({required this.head, required this.who, required this.sub, required this.kit, this.alert = false});

  final String head, who, sub;
  final Color kit;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (head.isEmpty && who.isEmpty) return const SizedBox();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: ShapeDecoration(
            shape: GlmCut.shape(10),
            gradient: LinearGradient(colors: alert ? [p.goldLight, p.gold] : [kit, Color.lerp(kit, Colors.black, .3)!]),
          ),
          child: Text(
            head,
            style: glmText(
              GlmType.body,
              color: alert ? p.onGold : (kit.computeLuminance() > .5 ? Colors.black : Colors.white),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: ShapeDecoration(shape: GlmCut.shape(10), color: Colors.black.withValues(alpha: .72)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (who.isNotEmpty)
                  Text(
                    who,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    style: glmText(GlmType.body, color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                if (sub.isNotEmpty)
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: glmText(GlmType.caption, color: p.goldLight, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, {required this.live});

  final String label;
  final bool live;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: ShapeDecoration(shape: GlmCut.shape(6), color: live ? context.palette.danger : Colors.black.withValues(alpha: .6)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (live) ...[const Icon(Icons.circle, size: 7, color: Colors.white), const SizedBox(width: 4)],
        Text(
          label,
          style: glmText(GlmType.caption, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5),
        ),
      ],
    ),
  );
}

/// «GOAL!» on a gold slab in the Legend Cut, bursting in at the key moment, the scorer's name under it.
class _GoalBanner extends StatelessWidget {
  const _GoalBanner({required this.t, required this.who, required this.ar});

  final double t;
  final String who;
  final bool ar;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (t > 2.6) return const SizedBox();
    final inK = Curves.elasticOut.transform((t / .7).clamp(0, 1));
    final out = ((t - 2.1) / .5).clamp(0.0, 1.0);
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -.35),
        child: Opacity(
          opacity: 1 - out,
          child: Transform.scale(
            scale: .4 + .6 * inK,
            child: Transform.rotate(
              angle: -.06,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 10),
                decoration: ShapeDecoration(
                  shape: GlmCut.shape(18, side: const BorderSide(color: Colors.white, width: 2)),
                  gradient: LinearGradient(colors: [p.goldLight, p.gold, p.goldDark], stops: const [0, .5, 1]),
                  shadows: [BoxShadow(color: p.gold.withValues(alpha: .6), blurRadius: 30, spreadRadius: -2)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      L.of(context).goalShout,
                      style: glmText(
                        GlmType.displayLg,
                        fontFamily: ar ? GlmFonts.body : GlmFonts.numbers,
                        fontWeight: FontWeight.w800,
                        color: p.onGold,
                        height: 1.05,
                        letterSpacing: ar ? 0 : 4,
                      ),
                    ),
                    if (who.isNotEmpty)
                      Text(
                        who,
                        textDirection: TextDirection.ltr,
                        style: glmText(GlmType.body, fontWeight: FontWeight.w800, color: p.onGold),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gold and club-coloured confetti falling after a goal.
class _Confetti extends CustomPainter {
  _Confetti({required this.t, required this.gold, required this.kit});

  final double t;
  final Color gold, kit;

  @override
  void paint(Canvas canvas, Size s) {
    if (t > 3.5) return;
    final rnd = math.Random(21);
    for (var i = 0; i < 60; i++) {
      final x0 = rnd.nextDouble() * s.width, delay = rnd.nextDouble() * .5, speed = 120 + rnd.nextDouble() * 160;
      final k = t - delay;
      if (k <= 0) continue;
      final y = -10 + k * speed;
      if (y > s.height) continue;
      final x = x0 + math.sin(k * 4 + i) * 18;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(k * 6 + i);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 7, height: 4),
        Paint()..color = (i % 3 == 0 ? kit : gold).withValues(alpha: (1 - t / 3.5).clamp(0, 1)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Confetti old) => old.t != t;
}
