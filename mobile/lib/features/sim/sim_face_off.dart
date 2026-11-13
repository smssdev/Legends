import '../../ui/art_palette.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/motion.dart';
import 'sim_repository.dart';

/// The face-off over the night pitch: the two crests slide in toward each other, the VS swings between them, the
/// floodlights sway and a ball bounces on the centre spot.
class FaceOff extends StatefulWidget {
  const FaceOff({super.key, required this.home, required this.away, required this.friend});

  final SimClub? home, away;
  final bool friend;

  @override
  State<FaceOff> createState() => _FaceOffState();
}

class _FaceOffState extends State<FaceOff> with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!still && Ambient.on) {
      if (!_loop.isAnimating) _loop.repeat();
    } else {
      _in.value = 1;
      _loop.stop();
    }
  }

  @override
  void dispose() {
    _in.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = glmNight;
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: AnimatedBuilder(
        animation: Listenable.merge([_in, _loop]),
        builder: (context, _) {
          final t = Curves.easeOutBack.transform(_in.value.clamp(0.0, 1.0));
          final w = math.sin(_loop.value * math.pi * 2);
          final bounce = (math.sin(_loop.value * math.pi * 2 * 1.4)).abs();
          Widget side(Widget crest, String name, bool start) => Transform.translate(
            offset: Offset((start ? 1 : -1) * (1 - t) * 120 * (Directionality.of(context) == TextDirection.rtl ? 1 : -1), w * 3),
            child: Opacity(
              opacity: _in.value.clamp(0.0, 1.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 76, child: Center(child: crest)),
                  const SizedBox(height: 4),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 120),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: p.bgDeep.withValues(alpha: .8), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: glmText(GlmType.caption, fontWeight: FontWeight.w800, color: p.text),
                    ),
                  ),
                ],
              ),
            ),
          );
          final away = widget.friend
              ? Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: p.gold, width: 3),
                  ),
                  child: Text(
                    '?',
                    style: glmText(GlmType.display, fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, color: p.gold),
                  ),
                )
              : widget.away != null
              ? ClubCrest(url: widget.away!.logo, name: widget.away!.code, size: 66, color: widget.away!.color)
              : Icon(Icons.smart_toy_rounded, size: 62, color: p.ring);
          return Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: p.bgDeep),
              CustomPaint(painter: _NightPitch(sway: w)),
              Row(
                children: [
                  Expanded(
                    child: side(
                      widget.home == null
                          ? const SizedBox(width: 66)
                          : ClubCrest(url: widget.home!.logo, name: widget.home!.code, size: 66, color: widget.home!.color),
                      widget.home?.name ?? '',
                      true,
                    ),
                  ),
                  Transform.scale(
                    scale: 1 + .1 * w,
                    child: Transform.rotate(
                      angle: .07 * w,
                      child: Text(
                        'VS',
                        style: glmText(
                          GlmType.displayLg,
                          fontFamily: GlmFonts.numbers,
                          fontWeight: FontWeight.w700,
                          color: p.gold,
                          shadows: [
                            Shadow(color: p.goldDark, offset: const Offset(0, 2)),
                            Shadow(color: p.gold.withValues(alpha: .55), blurRadius: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: side(away, widget.friend ? l.simWaitingFriend : widget.away?.name ?? l.simComputer, false)),
                ],
              ),
              Positioned(
                bottom: 12 + bounce * 26,
                left: 0,
                right: 0,
                child: Center(
                  child: CustomPaint(size: const Size.square(18), painter: BallPainter()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A night pitch in perspective under two swaying beams.
class _NightPitch extends CustomPainter {
  _NightPitch({required this.sway});

  final double sway;

  @override
  void paint(Canvas canvas, Size s) {
    final p = glmNight;
    for (final left in [true, false]) {
      canvas.save();
      canvas.translate(left ? 30 : s.width - 30, -10);
      canvas.rotate((left ? -.25 : .25) + .2 * sway * (left ? 1 : -1));
      final beam = Path()
        ..addPolygon([const Offset(-7, 0), const Offset(7, 0), Offset(70, s.height * 1.3), Offset(-70, s.height * 1.3)], true);
      canvas.drawPath(
        beam,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: GlmArt.floodlightGlow,
          ).createShader(Rect.fromLTWH(-70, 0, 140, s.height)),
      );
      canvas.restore();
    }
    final top = s.height * .54, k = s.width / 390;
    final field = Path()..addPolygon([Offset(80 * k, top), Offset(310 * k, top), Offset(s.width, s.height), Offset(0, s.height)], true);
    canvas.drawPath(field, Paint()..color = p.pitchDark);
    canvas.drawPath(
      Path()..addPolygon([Offset(118 * k, top), Offset(157 * k, top), Offset(140 * k, s.height), Offset(78 * k, s.height)], true),
      Paint()..color = p.pitch,
    );
    canvas.drawPath(
      Path()..addPolygon([Offset(195 * k, top), Offset(234 * k, top), Offset(250 * k, s.height), Offset(195 * k, s.height)], true),
      Paint()..color = p.pitch,
    );
    final line = Paint()
      ..color = p.text.withValues(alpha: .45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(field, line);
    canvas.drawOval(Rect.fromCenter(center: Offset(s.width / 2, top + (s.height - top) * .4), width: 108 * k, height: 28), line);
  }

  @override
  bool shouldRepaint(_NightPitch old) => old.sway != sway;
}
