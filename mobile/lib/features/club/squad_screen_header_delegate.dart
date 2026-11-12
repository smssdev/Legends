part of 'squad_screen.dart';

/// The table's blue header, kept in sight while the list scrolls; a tap on a column sorts by it.
class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate(this.state);

  final _SquadScreenState state;

  @override
  double get minExtent => 44;
  @override
  double get maxExtent => 44;

  @override
  Widget build(BuildContext context, double shrink, bool overlaps) {
    final l = L.of(context);
    return Container(
      color: GlmStage.pill,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: _Cells(
        name: _Head(l.colName, _Col.name, state),
        age: _Head(l.colAge, _Col.age, state),
        nat: _Head(l.colNat, null, state),
        pos: _Head(l.colPos, _Col.pos, state),
        ovr: _Head(l.colOvr, _Col.ovr, state),
        pot: _Head(l.colPot, _Col.pot, state),
        fit: _Head(l.colFit, _Col.fit, state),
        value: _Head(l.colValue, _Col.value, state),
      ),
    );
  }

  @override
  bool shouldRebuild(_HeaderDelegate old) => true;
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFEFF2F7),
    padding: const EdgeInsets.symmetric(vertical: 6),
    alignment: Alignment.center,
    child: Text(
      title,
      style: const TextStyle(color: Color(0xFF8C96A8), fontWeight: FontWeight.w700, fontSize: 16),
    ),
  );
}

/// The table's columns: the same widths in the header and each row.
class _Cells extends StatelessWidget {
  const _Cells({
    required this.name,
    required this.age,
    required this.nat,
    required this.pos,
    required this.ovr,
    required this.pot,
    required this.fit,
    required this.value,
  });

  final Widget name, age, nat, pos, ovr, pot, fit, value;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final roomy = box.maxWidth >= 640;
      return Row(
        children: [
          Expanded(child: name),
          SizedBox(width: 48, child: age),
          if (roomy) SizedBox(width: 92, child: nat),
          SizedBox(width: 58, child: pos),
          SizedBox(width: 54, child: ovr),
          if (roomy) SizedBox(width: 54, child: pot),
          SizedBox(width: roomy ? 110 : 58, child: fit),
          if (roomy) SizedBox(width: 84, child: value),
        ],
      );
    },
  );
}

class _Head extends StatelessWidget {
  const _Head(this.label, this.col, this.state);

  final String label;
  final _Col? col;
  final _SquadScreenState state;

  @override
  Widget build(BuildContext context) {
    final on = col != null && state._sort == col;
    final text = Row(
      mainAxisAlignment: col == _Col.name ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: on ? const Color(0xFFFFE36E) : Colors.white),
          ),
        ),
        if (on) Icon(state._desc ? Icons.arrow_drop_down_rounded : Icons.arrow_drop_up_rounded, size: 20, color: const Color(0xFFFFE36E)),
      ],
    );
    return col == null ? text : InkWell(onTap: () => state._by(col!), child: text);
  }
}

/// One player on a white row: his shirt (blue for the eleven, grey otherwise) with the captain's band, his name, age,
/// nationality, position, rating in bold, potential, fitness and condition as two green bars, and his value.
class _Row extends StatelessWidget {
  const _Row(this.p, {required this.onTap, this.captain = false});

  final Player p;
  final VoidCallback onTap;
  final bool captain;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF14203A), soft = Color(0xFFA2ABBB);
    const num = TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 24, color: ink);
    final starter = p.role == 'starter', bench = p.role == 'bench';
    final c = context.palette;
    Widget bar(double v, Color color) => Container(
      width: 46,
      height: 20,
      decoration: BoxDecoration(color: const Color(0xFFE3E7EE), borderRadius: BorderRadius.circular(3)),
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: v.clamp(.05, 1),
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
      ),
    );
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: BorderDirectional(
              bottom: const BorderSide(color: Color(0xFFEFF2F7)),
              start: BorderSide(color: starter ? const Color(0xFF6BE04A) : Colors.transparent, width: 5),
            ),
            gradient: starter
                ? LinearGradient(colors: [const Color(0xFF6BE04A).withValues(alpha: .10), Colors.white], stops: const [0, .35])
                : null,
          ),
          child: _Cells(
            name: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    KitShirt(
                      color: starter
                          ? GlmStage.pill
                          : bench
                          ? const Color(0xFF9AA4B5)
                          : const Color(0xFFD9DEE6),
                      trim: starter ? const Color(0xFFF3B71F) : Colors.white,
                      size: 38,
                    ),
                    if (captain)
                      Positioned(
                        bottom: -2,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(color: c.gold, borderRadius: BorderRadius.circular(3)),
                          child: const Text(
                            'C',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: ink),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, fontSize: 24, color: ink),
                  ),
                ),
                if (!p.available) ...[
                  const SizedBox(width: 6),
                  Icon(
                    p.injured > 0 ? Icons.local_hospital_rounded : Icons.style_rounded,
                    size: 20,
                    color: p.injured > 0 ? c.live : c.cardYellow,
                  ),
                ],
              ],
            ),
            age: Text(
              '${p.age}',
              textAlign: TextAlign.center,
              style: num.copyWith(fontWeight: FontWeight.w600),
            ),
            nat: p.nationCode == null
                ? Text(
                    p.nationality ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: soft),
                  )
                : Center(
                    child: Tooltip(
                      message: p.nationality ?? '',
                      child: NationFlag(code: p.nationCode!, colors: p.nationColors, width: 44),
                    ),
                  ),
            pos: Center(child: PositionChip(p.position, p.line)),
            // [Sprint 46, the polish] The rating on a pill tinted by its level.
            ovr: Center(
              child: Container(
                width: 46,
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: ArcGauge.levelColor(context, p.overall).withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ArcGauge.levelColor(context, p.overall).withValues(alpha: .7), width: 1.5),
                ),
                child: Text('${p.overall}', textAlign: TextAlign.center, style: num),
              ),
            ),
            pot: Text(
              '${p.potential}',
              textAlign: TextAlign.center,
              style: num.copyWith(color: p.potential > p.overall ? c.success : soft, fontWeight: FontWeight.w600),
            ),
            fit: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  bar(p.fitness / 100, fitnessColor(p.fitness)),
                  const SizedBox(width: 6),
                  bar(p.available ? 1 : .15, p.available ? const Color(0xFF8BE04E) : c.live),
                ],
              ),
            ),
            value: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    money(context, p.value),
                    textDirection: TextDirection.ltr,
                    style: num.copyWith(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 3),
                Image.asset('assets/brand/coin.png', width: 18, height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Money in short Western digits in every language (3.5M), as the game writes numbers (Sprint 30).
String money(BuildContext context, int v) => NumberFormat.compact(locale: 'en').format(v);

({Color bg, Color fg}) lineColor(String line) => switch (line) {
  'gk' => GlmLine.gk,
  'def' => GlmLine.def,
  'mid' => GlmLine.mid,
  _ => GlmLine.att,
};

Color fitnessColor(int f) => glmFitness.firstWhere((x) => f >= x.min, orElse: () => glmFitness.last).color;
