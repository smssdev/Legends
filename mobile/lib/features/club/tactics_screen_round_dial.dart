part of 'tactics_screen.dart';

const _cardFill = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [GlmStage.cardRaised, GlmStage.card]);
const _titleBlue = GlmTacticsArt.title;

/// The next match over the tactics: both crests and strengths, «VS», and the band of both formations under it.
class _NextCard extends StatelessWidget {
  const _NextCard({required this.s});

  final ClubSummary s;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final home = s.venue != 'away';
    Widget ring(int? v, bool mine) =>
        ArcGauge(value: v == null ? 0 : v ~/ 100, size: 62, color: mine ? context.palette.gold : GlmStage.accent);
    Widget side(Side? c, bool mine) => Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClubCrest(url: c?.crestUrl, name: c?.code ?? '', size: 62),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              c?.name ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: glmText(GlmType.display, fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
        ],
      ),
    );
    final (a, b) = home ? (s.club, s.next) : (s.next, s.club);
    final (sa, sb) = s.strength == null
        ? (null, null)
        : home
        ? (s.strength!.$1, s.strength!.$2)
        : (s.strength!.$2, s.strength!.$1);
    return ClipPath(
      clipper: ShapeBorderClipper(shape: GlmCut.shape(16), textDirection: Directionality.of(context)),
      child: Column(
        children: [
          SizedBox(
            height: 130,
            child: StadiumBackdrop(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    side(a, home),
                    ring(sa, home),
                    const SizedBox(width: 12),
                    Text(
                      'VS',
                      style: glmText(
                        GlmType.displayLg,
                        fontFamily: GlmFonts.numbers,
                        fontWeight: FontWeight.w800,
                        foreground: Paint()
                          ..shader = const LinearGradient(colors: [GlmTacticsArt.gold, GlmTacticsArt.goldDeep])
                              .createShader(const Rect.fromLTWH(0, 0, 70, 50)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ring(sb, !home),
                    side(b, !home),
                  ],
                ),
              ),
            ),
          ),
          Container(
            color: GlmStage.card,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const GameIcon(GameGlyph.lineup, size: 26),
                const SizedBox(width: 8),
                Text(
                  home ? (s.formation ?? '') : '',
                  style: glmText(GlmType.headline, fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const Spacer(),
                Text(
                  l.nextMatchShort,
                  style: glmText(GlmType.body, color: _titleBlue, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  home ? '' : (s.formation ?? ''),
                  style: glmText(GlmType.headline, fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                if (!home) ...[const SizedBox(width: 8), const GameIcon(GameGlyph.lineup, size: 26)],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A choice turned with its arrows (or a swipe): its title in blue, its value large, its picture, and a dot for each.
class _Carousel<T extends Object> extends StatelessWidget {
  const _Carousel({
    required this.title,
    required this.values,
    required this.value,
    required this.label,
    required this.picture,
    required this.onChanged,
  });

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
      color: GlmStage.pill,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => step(d),
        child: SizedBox.square(dimension: 44, child: Icon(icon, color: Colors.white, size: 28)),
      ),
    );
    return GestureDetector(
      onHorizontalDragEnd: (e) => step((e.primaryVelocity ?? 0) < 0 ? 1 : -1),
      child: Container(
        decoration: ShapeDecoration(shape: GlmCut.shape(14), gradient: _cardFill),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          children: [
            Text(
              title,
              style: glmText(GlmType.bodyLg, color: _titleBlue, fontWeight: FontWeight.w700),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                label(value),
                key: ValueKey(value),
                style: glmText(GlmType.headline, color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                arrow(Icons.chevron_right_rounded, -1),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(key: ValueKey(value), child: picture(value)),
                  ),
                ),
                arrow(Icons.chevron_left_rounded, 1),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var k = 0; k < values.length; k++)
                  Container(
                    width: 11,
                    height: 11,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: k == i ? Colors.white : Colors.white.withValues(alpha: .3)),
                  ),
              ],
            ),
          ],
        ),
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
      (
        'att',
        l.groupAtt,
        const ['only', 'support', 'back'],
        {'back': l.attBack, 'support': l.attSupport, 'only': l.attOnly},
        GlmTacticsArt.title,
      ),
      ('mid', l.groupMid, const ['push', 'stay', 'def'], {'def': l.midDef, 'stay': l.midStay, 'push': l.midPush}, GlmTacticsArt.mid),
      (
        'def',
        l.groupDef,
        const ['mid', 'fullbacks', 'stay'],
        {'stay': l.defStay, 'fullbacks': l.defFullbacks, 'mid': l.defMid},
        GlmTacticsArt.attack,
      ),
    ];
    return Container(
      decoration: ShapeDecoration(shape: GlmCut.shape(14), gradient: _cardFill),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Text(
                  l.positioning,
                  style: glmText(GlmType.bodyLg, color: _titleBlue, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                AspectRatio(
                  aspectRatio: .82,
                  child: CustomPaint(painter: _LinesArt('${t.values['att']}', '${t.values['mid']}', '${t.values['def']}')),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                for (final (key, title, values, labels, colour) in rows) ...[
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: glmText(GlmType.bodyLg, color: colour, fontWeight: FontWeight.w700),
                  ),
                  Row(
                    children: [
                      _Arrow(
                        Icons.chevron_right_rounded,
                        () => onSet(key, values[(values.indexOf('${t.values[key]}') - 1) % values.length]),
                      ),
                      Expanded(
                        child: Text(
                          labels['${t.values[key]}'] ?? '',
                          textAlign: TextAlign.center,
                          style: glmText(GlmType.title, color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                      ),
                      _Arrow(
                        Icons.chevron_left_rounded,
                        () => onSet(key, values[(values.indexOf('${t.values[key]}') + 1) % values.length]),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final v in values)
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: v == '${t.values[key]}' ? Colors.white : Colors.white.withValues(alpha: .3),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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
    color: GlmStage.pill,
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
