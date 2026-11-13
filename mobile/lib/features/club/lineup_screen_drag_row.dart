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
