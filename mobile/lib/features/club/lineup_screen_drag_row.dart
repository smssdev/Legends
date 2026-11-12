part of 'lineup_screen.dart';

/// [Sprint 45 M4] A bench or reserve player in the list: held a moment, he lifts and can be dropped on the pitch or on
/// another; a player dropped on him swaps with him.
class _DragRow extends StatelessWidget {
  const _DragRow({required this.player, required this.selected, required this.onTap, required this.onDrop});

  final Player player;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<int> onDrop;

  @override
  Widget build(BuildContext context) => DragTarget<int>(
    onWillAcceptWithDetails: (d) => d.data != player.id,
    onAcceptWithDetails: (d) => onDrop(d.data),
    builder: (context, over, _) => LongPressDraggable<int>(
      data: player.id,
      onDragStarted: HapticFeedback.mediumImpact,
      feedback: Material(
        type: MaterialType.transparency,
        child: Transform.scale(
          scale: 1.1,
          child: KitShirt(color: context.palette.gold, trim: Colors.white, label: '${player.overall}', size: 52, picked: true),
        ),
      ),
      childWhenDragging: Opacity(opacity: .4, child: PlayerRow(player)),
      child: PlayerRow(player, selected: selected || over.isNotEmpty, onTap: onTap),
    ),
  );
}

class _Lines extends CustomPainter {
  _Lines(this.color, {this.horizontal = false});

  final Color color;
  final bool horizontal;

  @override
  void paint(Canvas canvas, Size size) {
    // The mowing stripes, then the markings; drawn upright and turned a quarter for a pitch lying across.
    if (horizontal) {
      canvas.translate(size.width, 0);
      canvas.rotate(1.5707963267948966);
    }
    final s = horizontal ? Size(size.height, size.width) : size;
    final stripe = Paint()..color = Colors.black.withValues(alpha: .07);
    for (var i = 0; i < 10; i += 2) {
      canvas.drawRect(Rect.fromLTWH(0, s.height * i / 10, s.width, s.height / 10), stripe);
    }
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(6, 6, s.width - 12, s.height - 12), const Radius.circular(12)), pen);
    canvas.drawLine(Offset(6, s.height / 2), Offset(s.width - 6, s.height / 2), pen);
    canvas.drawCircle(Offset(s.width / 2, s.height / 2), s.width * .14, pen);
    canvas.drawCircle(Offset(s.width / 2, s.height / 2), 3, Paint()..color = color);
    for (final top in [true, false]) {
      final y = top ? 6.0 : s.height - 6;
      final d = top ? 1 : -1;
      canvas.drawRect(Rect.fromPoints(Offset(s.width * .22, y), Offset(s.width * .78, y + d * s.height * .15)), pen);
      canvas.drawRect(Rect.fromPoints(Offset(s.width * .38, y), Offset(s.width * .62, y + d * s.height * .06)), pen);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(s.width / 2, y + d * s.height * .15), radius: s.width * .09),
        top ? 0 : 3.141592653589793,
        3.141592653589793,
        false,
        pen,
      );
    }
  }

  @override
  bool shouldRepaint(_Lines old) => old.color != color || old.horizontal != horizontal;
}

enum _Mode { fitness, age, value }

/// [Sprint 46] The lineup on the stadium, landscape.
class _Arena extends StatefulWidget {
  const _Arena({
    required this.slots,
    required this.starters,
    required this.others,
    required this.team,
    required this.picked,
    required this.onTap,
    required this.onDrop,
    required this.formations,
    required this.formation,
    required this.onFormation,
    required this.leagueId,
    required this.save,
    required this.busy,
    required this.auto,
  });

  final List<Slot> slots;
  final List<int> starters;
  final List<Player> others;
  final TeamData team;
  final int? picked;
  final ValueChanged<int> onTap;
  final void Function(int dragged, int onto) onDrop;
  final List<Formation> formations;
  final String? formation;
  final ValueChanged<String> onFormation;
  final int leagueId;
  final VoidCallback? save;
  final bool busy;
  final VoidCallback auto;

  @override
  State<_Arena> createState() => _ArenaState();
}

class _ArenaState extends State<_Arena> {
  _Mode _mode = _Mode.fitness;
  bool _bench = false;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        // The pitch's trapezoid: its far line high and narrow, its near line low and wide.
        final top = h * .05, bottom = h * .98, farW = w * .56, nearW = w * 1.02;
        Offset place(double across, double fwd) {
          final y = lerpDouble(bottom - h * .06, top + h * .16, fwd)!;
          final k = (y - top) / (bottom - top);
          final width = lerpDouble(farW, nearW, k)!;
          return Offset(w / 2 + (across - .5) * width * .86, y);
        }

        const cardW = 150.0, cardH = 70.0;
        // Drawn at 150 × 70 and scaled to the room: smaller toward the far line, and with the screen's width.
        final room = (w / 1100).clamp(.55, 1.0);
        final rtl = Directionality.of(context) == TextDirection.rtl;
        final cards = <(double, Widget)>[];
        for (var i = 0; i < widget.slots.length && i < widget.starters.length; i++) {
          final pl = widget.team.byId(widget.starters[i]);
          if (pl == null) continue;
          final s = widget.slots[i];
          var across = (s.y / 680).clamp(0.0, 1.0);
          if (rtl) across = 1 - across;
          final at = place(across, (s.x / 740).clamp(0.0, 1.0));
          final k = lerpDouble(.8, 1.0, ((at.dy - top) / (bottom - top)).clamp(0.0, 1.0))! * room;
          // Its shadow on the grass.
          cards.add((
            at.dy - .1,
            Positioned(
              left: at.dx - cardW * k * .42,
              top: at.dy - 4,
              width: cardW * k * .84,
              height: 12 * k,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    color: Colors.black.withValues(alpha: .35),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .4), blurRadius: 8)],
                  ),
                ),
              ),
            ),
          ));
          cards.add((
            at.dy,
            Positioned(
              left: at.dx - cardW * k / 2,
              top: at.dy - cardH * k,
              width: cardW * k,
              height: cardH * k,
              child: _Drag(
                id: pl.id,
                onDrop: (d) => widget.onDrop(d, pl.id),
                child: GestureDetector(
                  onTap: () => widget.onTap(pl.id),
                  // [Sprint 46, the polish] The eleven drop onto their places one after another.
                  child: FadeSlideIn(
                    index: i,
                    offset: -24,
                    child: FittedBox(
                      child: SizedBox(
                        width: cardW,
                        height: cardH,
                        child: _Card(pl, mode: _mode, picked: widget.picked == pl.id, starter: true, captain: widget.team.captain == pl.id),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ));
        }
        cards.sort((a, b) => a.$1.compareTo(b.$1));
        Widget round(Widget icon, String tip, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Tooltip(
            message: tip,
            child: Material(
              shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 3)),
              color: GlmStage.cardRaised,
              elevation: 4,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: SizedBox.square(dimension: 56, child: Center(child: icon)),
              ),
            ),
          ),
        );
        Widget labelled(Widget icon, String label, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 44,
                decoration: const BoxDecoration(
                  color: GlmStage.card,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Center(child: icon),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: ShapeDecoration(
                  shape: GlmCut.shape(8, side: const BorderSide(color: GlmStage.edge)),
                  color: GlmStage.card,
                ),
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ],
          ),
        );
        final modeIcon = switch (_mode) {
          _Mode.fitness => Icons.fitness_center_rounded,
          _Mode.age => Icons.cake_rounded,
          _Mode.value => Icons.payments_rounded,
        };
        final modeLabel = switch (_mode) {
          _Mode.fitness => l.modeFitness,
          _Mode.age => l.modeAge,
          _Mode.value => l.modeValue,
        };
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ArenaPitch(grass: p.pitch, dark: p.pitchDark, top: top, bottom: bottom, farW: farW, nearW: nearW),
              ),
            ),
            for (final c in cards) c.$2,
            // The tactics and the specialists at the side.
            PositionedDirectional(
              end: 14,
              top: 10,
              child: Column(
                children: [
                  round(const GameIcon(GameGlyph.tactics, size: 34), l.tactics, () => context.push('/leagues/${widget.leagueId}/tactics')),
                  round(
                    const GameIcon(GameGlyph.specialists, size: 34),
                    l.specialists,
                    () => context.push('/leagues/${widget.leagueId}/specialists'),
                  ),
                  round(const Icon(Icons.auto_awesome_rounded, color: Colors.white), l.autoLineup, widget.auto),
                ],
              ),
            ),
            // The formation at the other corner.
            PositionedDirectional(
              start: 14,
              top: 10,
              child: PopupMenuButton<String>(
                onSelected: widget.onFormation,
                itemBuilder: (_) => [
                  for (final f in widget.formations)
                    PopupMenuItem(
                      value: f.name,
                      child: Text(
                        f.label,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                    ),
                ],
                child: labelled(const GameIcon(GameGlyph.lineup, size: 30), widget.formation ?? '', () {}),
              ),
            ),
            // The bench's panel and «save» below.
            PositionedDirectional(
              end: 14,
              bottom: 10,
              child: Row(
                children: [
                  labelled(
                    const Icon(Icons.event_seat_rounded, color: Colors.white, size: 26),
                    l.benchPanel,
                    () => setState(() => _bench = !_bench),
                  ),
                  const SizedBox(width: 12),
                  if (widget.save != null || widget.busy)
                    SizedBox(
                      width: 150,
                      child: GlmButton(label: l.save, loading: widget.busy, icon: const Icon(Icons.check_rounded), onPressed: widget.save),
                    ),
                ],
              ),
            ),
            PositionedDirectional(
              start: 14,
              bottom: 10,
              child: labelled(
                Icon(modeIcon, color: Colors.white, size: 26),
                modeLabel,
                () => setState(() => _mode = _Mode.values[(_mode.index + 1) % _Mode.values.length]),
              ),
            ),
            if (_bench)
              Positioned(
                left: w * .06,
                right: w * .06,
                bottom: 12,
                height: h * .5,
                child: _BenchPanel(
                  others: widget.others,
                  mode: _mode,
                  picked: widget.picked,
                  onTap: widget.onTap,
                  onDrop: widget.onDrop,
                  close: () => setState(() => _bench = false),
                ),
              ),
          ],
        );
      },
    );
  }
}
