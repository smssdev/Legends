part of 'lineup_screen.dart';

/// The pitch in perspective on the stadium: the stands, the grass with its stripes, its lines and the near box.
class _ArenaPitch extends CustomPainter {
  _ArenaPitch({required this.grass, required this.dark, required this.top, required this.bottom, required this.farW, required this.nearW});

  final Color grass, dark;
  final double top, bottom, farW, nearW;

  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s;
    c.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [GlmStage.deep, GlmStage.card],
        ).createShader(r),
    );
    // The crowd: dots in the stands around the pitch.
    final rnd = math.Random(4);
    final dot = Paint();
    for (var i = 0; i < 1400; i++) {
      final x = rnd.nextDouble() * s.width, y = rnd.nextDouble() * s.height;
      dot.color = Colors.white.withValues(alpha: .04 + rnd.nextDouble() * .08);
      c.drawCircle(Offset(x, y), 1.4, dot);
    }
    Offset at(double u, double v) {
      final y = lerpDouble(top, bottom, v)!;
      final width = lerpDouble(farW, nearW, v)!;
      return Offset(s.width / 2 + (u - .5) * width, y);
    }

    final field = Path()
      ..moveTo(at(0, 0).dx, at(0, 0).dy)
      ..lineTo(at(1, 0).dx, at(1, 0).dy)
      ..lineTo(at(1, 1).dx, at(1, 1).dy)
      ..lineTo(at(0, 1).dx, at(0, 1).dy)
      ..close();
    c.drawPath(
      field.shift(const Offset(0, 8)),
      Paint()
        ..color = Colors.black.withValues(alpha: .35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    c.drawPath(
      field,
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [dark, grass]).createShader(r),
    );
    c.save();
    c.clipPath(field);
    final stripe = Paint()..color = Colors.white.withValues(alpha: .05);
    for (var i = 0; i < 12; i += 2) {
      final v0 = i / 12, v1 = (i + 1) / 12;
      c.drawPath(
        Path()
          ..moveTo(at(0, v0).dx, at(0, v0).dy)
          ..lineTo(at(1, v0).dx, at(1, v0).dy)
          ..lineTo(at(1, v1).dx, at(1, v1).dy)
          ..lineTo(at(0, v1).dx, at(0, v1).dy)
          ..close(),
        stripe,
      );
    }
    c.restore();
    final line = Paint()
      ..color = Colors.white.withValues(alpha: .85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final inset = Path()
      ..moveTo(at(.03, .02).dx, at(.03, .02).dy)
      ..lineTo(at(.97, .02).dx, at(.97, .02).dy)
      ..lineTo(at(.97, .97).dx, at(.97, .97).dy)
      ..lineTo(at(.03, .97).dx, at(.03, .97).dy)
      ..close();
    c.drawPath(inset, line);
    c.drawLine(at(.03, .4), at(.97, .4), line);
    final mid = at(.5, .4);
    c.drawOval(Rect.fromCenter(center: mid, width: lerpDouble(farW, nearW, .4)! * .2, height: s.height * .14), line);
    // The near box and the six-yard box.
    for (final (w, d) in [(.5, .2), (.24, .07)]) {
      c.drawPath(
        Path()
          ..moveTo(at(.5 - w / 2, .97).dx, at(.5 - w / 2, .97).dy)
          ..lineTo(at(.5 - w / 2, .97 - d).dx, at(.5 - w / 2, .97 - d).dy)
          ..lineTo(at(.5 + w / 2, .97 - d).dx, at(.5 + w / 2, .97 - d).dy)
          ..lineTo(at(.5 + w / 2, .97).dx, at(.5 + w / 2, .97).dy),
        line,
      );
    } // [Sprint 46, the polish] The far goal, the floodlights' beams falling on the grass from both corners, their glow,
    // and the night closing in at the edges.
    final g0 = at(.44, 0), g1 = at(.56, 0);
    final goal = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    c.drawPath(
      Path()
        ..moveTo(g0.dx, g0.dy)
        ..lineTo(g0.dx, g0.dy - s.height * .05)
        ..lineTo(g1.dx, g1.dy - s.height * .05)
        ..lineTo(g1.dx, g1.dy),
      goal,
    );
    for (final x in [0.0, s.width]) {
      final o = Offset(x, 0);
      c.drawPath(
        Path()
          ..moveTo(x, 0)
          ..lineTo(s.width * .5 + (x == 0 ? -s.width * .05 : s.width * .05), bottom)
          ..lineTo(s.width * .5 + (x == 0 ? -s.width * .35 : s.width * .35), bottom)
          ..close(),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white.withValues(alpha: .10), Colors.white.withValues(alpha: 0)],
          ).createShader(r),
      );
      c.drawCircle(
        o,
        s.width * .22,
        Paint()
          ..shader = RadialGradient(colors: [const Color(0xFFFFE9B0).withValues(alpha: .35), const Color(0xFFFFE9B0).withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: o, radius: s.width * .22)),
      );
    }
    c.drawRect(
      r,
      Paint()
        ..shader = RadialGradient(
          radius: .9,
          colors: [Colors.transparent, Colors.black.withValues(alpha: .35)],
          stops: const [.65, 1],
        ).createShader(r),
    );
  }

  @override
  bool shouldRepaint(_ArenaPitch old) => old.farW != farW || old.top != top;
}

/// A player's card on the pitch or the bench: navy lit from the top, a green edge for the eleven (gold when picked).
/// What it shows follows the mode: his rating, his line's letters and fitness and availability as two bars; his age,
/// nation and potential; his value.
class _Card extends StatelessWidget {
  const _Card(this.p, {required this.mode, this.picked = false, this.starter = false, this.captain = false});

  final Player p;
  final _Mode mode;
  final bool picked, starter, captain;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final edge = picked
        ? c.gold
        : starter
        ? const Color(0xFF6BE04A)
        : GlmStage.edge;
    final big = const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 24, color: Colors.white, height: 1);
    final small = const TextStyle(color: Color(0xFFB9C7E3), fontWeight: FontWeight.w700, fontSize: 11, height: 1);
    Widget bar(double v, Color color) => Container(
      width: 34,
      height: 9,
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: .4), borderRadius: BorderRadius.circular(2)),
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: v.clamp(.05, 1),
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
      ),
    );
    final body = switch (mode) {
      _Mode.fitness => Row(
        children: [
          Text(
            '${p.overall}',
            style: big.copyWith(
              color: ArcGauge.levelColor(context, p.overall) == c.textMuted ? Colors.white : ArcGauge.levelColor(context, p.overall),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Center(child: Icon(Icons.person_rounded, size: 34, color: Colors.white.withValues(alpha: .25))),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              bar(p.fitness / 100, fitnessColor(p.fitness)),
              const SizedBox(height: 5),
              bar(p.available ? 1 : .15, p.available ? const Color(0xFF6BE04A) : c.live),
            ],
          ),
        ],
      ),
      _Mode.age => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(L.of(context).modeAge, style: small),
              const SizedBox(height: 3),
              Text('${p.age}', style: big),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(L.of(context).colPot, style: small),
              const SizedBox(height: 3),
              Text('${p.potential}', style: big),
            ],
          ),
          if (p.nationCode != null) NationFlag(code: p.nationCode!, colors: p.nationColors, width: 34),
        ],
      ),
      _Mode.value => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/brand/coin.png', width: 18, height: 18),
          const SizedBox(width: 6),
          Text(money(context, p.value), textDirection: TextDirection.ltr, style: big),
        ],
      ),
    };
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: GlmCut.shape(12, side: BorderSide(color: edge, width: 3)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [GlmStage.cardRaised, GlmStage.card],
        ),
        shadows: [
          BoxShadow(color: (starter ? const Color(0xFF6BE04A) : Colors.black).withValues(alpha: .35), blurRadius: 10, spreadRadius: -2),
        ],
      ),
      child: Stack(
        children: [
          // A glossy band across the card's upper half.
          Positioned(
            left: 4,
            right: 4,
            top: 3,
            height: 22,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withValues(alpha: .16), Colors.white.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 5, 10, 4),
            child: Column(
              children: [
                Row(
                  children: [
                    PositionChip(p.position, p.line),
                    const Spacer(),
                    // The captain's armband.
                    if (captain)
                      Container(
                        margin: const EdgeInsetsDirectional.only(end: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(color: c.gold, borderRadius: BorderRadius.circular(3)),
                        child: Text(
                          'C',
                          style: TextStyle(color: c.onGold, fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                      ),
                    if (!p.available) Icon(p.injured > 0 ? Icons.local_hospital_rounded : Icons.style_rounded, size: 14, color: c.live),
                  ],
                ),
                Expanded(child: body),
                Text(
                  p.name.split(' ').last.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: GlmFonts.numbers,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A card that can be dragged and dropped on another: the two swap.
class _Drag extends StatelessWidget {
  const _Drag({required this.id, required this.onDrop, required this.child});

  final int id;
  final ValueChanged<int> onDrop;
  final Widget child;

  @override
  Widget build(BuildContext context) => DragTarget<int>(
    onWillAcceptWithDetails: (d) => d.data != id,
    onAcceptWithDetails: (d) => onDrop(d.data),
    builder: (context, over, _) => Draggable<int>(
      data: id,
      onDragStarted: HapticFeedback.selectionClick,
      feedback: Material(
        type: MaterialType.transparency,
        child: Opacity(opacity: .9, child: SizedBox(width: 150, height: 70, child: child)),
      ),
      childWhenDragging: Opacity(opacity: .35, child: child),
      child: AnimatedScale(scale: over.isNotEmpty ? 1.08 : 1, duration: const Duration(milliseconds: 140), child: child),
    ),
  );
}

/// The bench and the rest by line, in a panel over the pitch's near half; a card dragged from it onto one of the eleven
/// takes his place (or a tap on each).
class _BenchPanel extends StatelessWidget {
  const _BenchPanel({
    required this.others,
    required this.mode,
    required this.picked,
    required this.onTap,
    required this.onDrop,
    required this.close,
  });

  final List<Player> others;
  final _Mode mode;
  final int? picked;
  final ValueChanged<int> onTap;
  final void Function(int dragged, int onto) onDrop;
  final VoidCallback close;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final lines = [('att', l.groupAtt), ('mid', l.groupMid), ('def', l.groupDef), ('gk', l.groupGk)];
    return Material(
      shape: GlmCut.shape(16, side: const BorderSide(color: GlmStage.accent, width: 3)),
      color: GlmStage.card.withValues(alpha: .96),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (line, title) in lines)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            children: [
                              for (final p in others.where((p) => p.line == line))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: SizedBox(
                                    height: 66,
                                    child: _Drag(
                                      id: p.id,
                                      onDrop: (d) => onDrop(d, p.id),
                                      child: GestureDetector(
                                        onTap: () => onTap(p.id),
                                        child: _Card(p, mode: mode, picked: picked == p.id),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          PositionedDirectional(
            top: 2,
            end: 2,
            child: IconButton(
              onPressed: close,
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
