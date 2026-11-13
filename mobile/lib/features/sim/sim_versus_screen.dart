import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/sounds.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/motion.dart';
import 'sim_repository.dart';
import 'sim_versus_art.dart';

/// [Sprint 47] The face-off before the match, the approved design's motion graphic: the screen split on a gold
/// diagonal in the two sides' colours, speed lines running, the crests slamming in one after the other, the VS
/// crashing between them with a flash ring, the three lines' strength bars filling, sparks rising, and the countdown
/// ring to the kick-off. Then the way into the match (and, against a friend, the invite).
class SimVersusScreen extends StatefulWidget {
  const SimVersusScreen({super.key, required this.home, required this.away, required this.friend, required this.matchUrl, this.inviteUrl});

  final SimClub home, away;
  final bool friend;
  final String matchUrl;
  final String? inviteUrl;

  static const length = Duration(milliseconds: 3600);

  @override
  State<SimVersusScreen> createState() => _SimVersusScreenState();
}

class _SimVersusScreenState extends State<SimVersusScreen> with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: SimVersusScreen.length);
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (still || !Ambient.on) {
        _c.value = 1;
        return;
      }
      _loop.repeat();
      _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _loop.dispose();
    super.dispose();
  }

  double _seg(double a, double b, [Curve curve = Curves.linear]) {
    final s = _c.value * SimVersusScreen.length.inMilliseconds / 1000;
    return curve.transform(((s - a) / (b - a)).clamp(0.0, 1.0));
  }

  Future<void> _open() async {
    unawaited(GameSounds.play(Sfx.whistle));
    await launchUrl(Uri.parse(widget.matchUrl), mode: LaunchMode.inAppBrowserView);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = glmNight;
    final homeColor = widget.home.color ?? p.live;
    final awayColor = widget.away.color ?? const Color(0xFF2F6FDB);
    // The strength of each line from the club's (the simulator shows the real squads on its page).
    final hs = widget.home.strength ?? 75, as = widget.away.strength ?? 75;
    return Scaffold(
      backgroundColor: p.bgDeep,
      body: AnimatedBuilder(
        animation: Listenable.merge([_c, _loop]),
        builder: (context, _) {
          final slamH = _seg(0, .8, Curves.elasticOut);
          final slamA = _seg(.3, 1.1, Curves.elasticOut);
          final vs = _seg(1.1, 1.6, Curves.easeOutBack);
          final flash = _seg(1.2, 2.0, Curves.easeOut);
          final bars = _seg(1.5, 2.6, Curves.easeOutCubic);
          final ring = _seg(2.2, 3.6);
          final done = _c.value >= 1;
          final wide = MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
          final title = Text(
            '${l.simTitle} · ${widget.friend ? l.simVsFriend : l.simVsCpu}',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.chrome, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: .5),
          );
          final vsMark = SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (flash > 0 && flash < 1)
                  Container(
                    width: 70 * (1 + flash * 2.2),
                    height: 70 * (1 + flash * 2.2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: p.gold.withValues(alpha: (1 - flash) * .9), width: 4),
                    ),
                  ),
                Transform.scale(
                  scale: vs * (1 + .06 * math.sin(_loop.value * math.pi * 2)),
                  child: Transform.rotate(
                    angle: (1 - vs) * -.7,
                    child: Text(
                      'VS',
                      style: TextStyle(
                        fontFamily: GlmFonts.numbers,
                        fontWeight: FontWeight.w700,
                        fontSize: 76,
                        height: 1,
                        color: p.gold,
                        shadows: [
                          Shadow(color: p.goldDark, offset: const Offset(0, 4)),
                          Shadow(color: p.gold.withValues(alpha: .7), blurRadius: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
          final duels = Opacity(
            opacity: _seg(1.4, 1.9),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.bgDeep.withValues(alpha: .78),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: p.surfaceRaised),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (i, label) in [l.simAttack, l.simMidfield, l.simDefence].indexed)
                    Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                      child: _Duel(
                        label: label,
                        home: (hs + [3, 0, -2][i]).clamp(1, 99),
                        away: (as + [-2, 1, 0][i]).clamp(1, 99),
                        t: bars,
                        homeColor: homeColor,
                        awayColor: awayColor,
                      ),
                    ),
                ],
              ),
            ),
          );
          final start = GlmButton(label: l.simStart, block: true, icon: const Icon(Icons.play_arrow_rounded), onPressed: _open);
          final invite = widget.inviteUrl == null
              ? null
              : GlmButton(
                  label: l.simInvite,
                  block: true,
                  variant: GlmButtonVariant.brand,
                  icon: const Icon(Icons.share_rounded),
                  onPressed: () => SharePlus.instance.share(ShareParams(text: l.simInviteText(widget.inviteUrl!))),
                );
          final countdown = Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(value: ring, strokeWidth: 5, color: p.gold, backgroundColor: p.surfaceRaised),
                    ),
                    Text(
                      '${(3 - (ring * 3).floor()).clamp(1, 3)}',
                      style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, fontSize: 28, color: p.gold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Text(
                l.simKickoff,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: p.text),
              ),
            ],
          );
          // [Sprint 47] Landscape (the app's way): the crests at either side of the screen, the VS and the duels
          // between them, the way in at the foot. Upright: the crests one above the other on the diagonal.
          final scene = wide
              ? SizedBox(
                  width: 844,
                  height: 390,
                  child: Stack(
                    children: [
                      Positioned(top: 12, left: 0, right: 0, child: title),
                      PositionedDirectional(
                        top: 54,
                        start: 36,
                        child: _Slam(t: slamH, from: const Offset(260, 0), club: widget.home, tint: homeColor),
                      ),
                      PositionedDirectional(
                        top: 54,
                        end: 36,
                        child: _Slam(t: slamA, from: const Offset(-260, 0), club: widget.away, tint: awayColor),
                      ),
                      Positioned(top: 34, left: 0, right: 0, child: Center(child: vsMark)),
                      Positioned(
                        top: 160,
                        left: 0,
                        right: 0,
                        child: Center(child: SizedBox(width: 380, child: duels)),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 14,
                        child: Center(
                          child: SizedBox(
                            width: done && invite != null ? 560 : 380,
                            child: done
                                ? Row(
                                    children: [
                                      Expanded(child: start),
                                      if (invite != null) ...[const SizedBox(width: 12), Expanded(child: invite)],
                                    ],
                                  )
                                : countdown,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : SizedBox(
                  width: 390,
                  height: 780,
                  child: Stack(
                    children: [
                      Positioned(top: 14, left: 0, right: 0, child: title),
                      PositionedDirectional(
                        top: 40,
                        start: 28,
                        child: _Slam(t: slamH, from: const Offset(160, -120), club: widget.home, tint: homeColor),
                      ),
                      PositionedDirectional(
                        top: 318,
                        end: 28,
                        child: _Slam(t: slamA, from: const Offset(-160, 120), club: widget.away, tint: awayColor),
                      ),
                      Positioned(top: 222, left: 0, right: 0, child: Center(child: vsMark)),
                      Positioned(left: 22, right: 22, bottom: 146, child: duels),
                      Positioned(
                        left: 22,
                        right: 22,
                        bottom: 26,
                        child: done
                            ? Column(
                                children: [
                                  start,
                                  if (invite != null) ...[const SizedBox(height: 10), invite],
                                ],
                              )
                            : countdown,
                      ),
                    ],
                  ),
                );
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: SimSplit(home: homeColor, away: awayColor, gold: p.gold, run: _loop.value, wide: wide),
              ),
              CustomPaint(
                painter: SimSparks(t: _loop.value, colors: [p.gold, p.ring, p.text]),
              ),
              SafeArea(
                child: Center(
                  child: FittedBox(fit: BoxFit.scaleDown, child: scene),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: CloseButton(color: p.text),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A crest slamming into place from off the screen, with its name and strength.
class _Slam extends StatelessWidget {
  const _Slam({required this.t, required this.from, required this.club, required this.tint});

  final double t;
  final Offset from;
  final SimClub club;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = glmNight;
    final k = 1 - t;
    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: from * k,
        child: Transform.scale(
          scale: 1 + k * 1.4,
          child: Transform.rotate(
            angle: k * .3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClubCrest(url: club.logo, name: club.code, size: 104, color: club.color),
                const SizedBox(height: 8),
                SizedBox(
                  width: 200,
                  child: Text(
                    club.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: p.text),
                  ),
                ),
                if (club.strength != null)
                  Text(
                    l.simStrength(club.strength!),
                    style: TextStyle(
                      fontFamily: GlmFonts.body,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color.lerp(tint, Colors.white, .45),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One line's strength, home against away, the bars filling from the middle.
class _Duel extends StatelessWidget {
  const _Duel({
    required this.label,
    required this.home,
    required this.away,
    required this.t,
    required this.homeColor,
    required this.awayColor,
  });

  final String label;
  final int home, away;
  final double t;
  final Color homeColor, awayColor;

  @override
  Widget build(BuildContext context) {
    final p = glmNight;
    Widget bar(int v, Color c, AlignmentDirectional from) => Expanded(
      child: Container(
        height: 8,
        decoration: BoxDecoration(color: p.text.withValues(alpha: .1), borderRadius: BorderRadius.circular(4)),
        alignment: from,
        child: FractionallySizedBox(
          widthFactor: (v / 100 * t).clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
          ),
        ),
      ),
    );
    TextStyle n() => TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, fontSize: 17, color: p.text);
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text('$home', textAlign: TextAlign.center, style: n()),
        ),
        bar(home, homeColor, AlignmentDirectional.centerEnd),
        SizedBox(
          width: 56,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: p.textSoft),
          ),
        ),
        bar(away, awayColor, AlignmentDirectional.centerStart),
        SizedBox(
          width: 30,
          child: Text('$away', textAlign: TextAlign.center, style: n()),
        ),
      ],
    );
  }
}
