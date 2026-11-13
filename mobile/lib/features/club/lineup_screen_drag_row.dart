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
