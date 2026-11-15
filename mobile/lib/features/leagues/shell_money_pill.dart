part of 'shell.dart';

/// [Sprint 50] The club's money, as the site's .pill-money: an emerald-tinted pill with green figures, «+» to finance.
class MoneyPill extends StatelessWidget {
  const MoneyPill({super.key, required this.value, this.onTap});

  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // [Sprint 65 F3] Drawn 32 high in the 42 bar, answering the finger over 48.
    return GlmTarget(
      child: Semantics(
        button: true,
        label: '${L.of(context).finance}: $value',
        child: Material(
          color: p.success.withValues(alpha: .18),
          shape: StadiumBorder(side: BorderSide(color: p.success.withValues(alpha: .35))),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: 32,
              padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 4, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    textDirection: TextDirection.ltr,
                    style: glmText(
                      GlmType.bodyLg,
                      fontFamily: GlmFonts.numbers,
                      fontWeight: FontWeight.w700,
                      color: context.glm.successText,
                    ),
                  ),
                  const SizedBox(width: 5),
                  _Plus(bg: p.success, fg: p.bgDeep),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Plus extends StatelessWidget {
  const _Plus({required this.bg, required this.fg});

  final Color bg, fg;

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
    child: Icon(Icons.add_rounded, size: 16, color: fg),
  );
}

/// [Sprint 50] A round icon of the top bar, as the site's .bar-icon (a 44px touch on a 36px circle), with its badge.
class BarIcon extends StatelessWidget {
  const BarIcon({super.key, required this.icon, required this.label, this.onTap, this.badge});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // [Sprint 65 F3] Drawn 44 in the 42 bar, answering the finger over 48.
    return GlmTarget(
      child: Semantics(
        button: true,
        label: label,
        child: InkResponse(
          onTap: onTap,
          radius: 22,
          child: SizedBox.square(
            dimension: 44,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: p.text.withValues(alpha: .1), shape: BoxShape.circle),
                    child: Icon(icon, size: 19, color: p.text),
                  ),
                  if (badge != null)
                    PositionedDirectional(
                      top: -3,
                      end: -3,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16),
                        height: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(color: p.live, borderRadius: BorderRadius.circular(8)),
                        alignment: Alignment.center,
                        child: Text(
                          badge!,
                          style: glmText(GlmType.caption, fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The next match's countdown on the top bar (the site's timers), ticking each second.
class _Countdown extends StatefulWidget {
  const _Countdown({required this.at});

  final DateTime at;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  late final _tick = Stream<int>.periodic(const Duration(seconds: 1), (i) => i);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // [Sprint 61 F5] The second's tick repaints only the clock.
    return RepaintBoundary(
      child: StreamBuilder<int>(
        stream: _tick,
        builder: (context, _) {
          final left = widget.at.difference(DateTime.now());
          if (left.isNegative || left.inHours >= 100) return const SizedBox.shrink();
          String two(int n) => n.toString().padLeft(2, '0');
          final text = '${two(left.inHours)}:${two(left.inMinutes % 60)}:${two(left.inSeconds % 60)}';
          return Semantics(
            label: '${L.of(context).nextMatch}: $text',
            excludeSemantics: true,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(color: p.text.withValues(alpha: .1), borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule_rounded, size: 16, color: p.gold),
                  const SizedBox(width: 5),
                  Text(
                    text,
                    textDirection: TextDirection.ltr,
                    style: glmText(GlmType.body, fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, color: p.text),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

typedef _Entry = ({GlmIcons icon, String label, String path, bool push});

/// [Sprint 50 M2] The dock: the site's section row stood on its side, 72px on the screen's start. The club's crest at
/// its top (to the office), then each section: a gold icon over its name, the open one gold with a gold bar on the
/// dock's edge and a light ground. A section of one page goes there; a section of several opens their list beside the
/// dock (the site's .nav-panel: the open page on the brand green). A live match pulses red on the match's section.
class ConsoleDock extends ConsumerWidget {
  const ConsoleDock({super.key, required this.leagueId, required this.location});

  final int leagueId;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = context.palette;
    final s = ref.watch(clubSummaryProvider(leagueId)).value;
    final base = '/leagues/$leagueId';
    // [Sprint 60 F1] The six sections and «More» from docs/design/nav.json (lib/l10n/nav.g.dart), the site's too: each
    // page by the one name the site gives it, in this language.
    final lang = Localizations.localeOf(context).languageCode;
    _Section section(NavSection x) => (
      // [Sprint 63 G3] The site's same icons, from brand/icons (nav.json names them for both).
      icon: GlmIcons.values.byName(_camel(x.icon)),
      tile: x.color == null ? null : (colour: _tileColour(context, x.color!), dark: x.ink == 'dark'),
      label: x.label(lang),
      entries: [
        for (final y in x.pages)
          (icon: GlmIcons.values.byName(_camel(y.icon)), label: y.label(lang), path: y.route(leagueId), push: y.push),
      ],
      badge: x.key == 'match' && s?.matchStatus == 'live' ? 'live' : null,
    );
    final sections = [
      for (final x in [...navDock, navMore]) section(x),
    ];
    return Container(
      width: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.bgDeep.withValues(alpha: .92), p.panel.withValues(alpha: .88)],
        ),
        border: BorderDirectional(end: BorderSide(color: p.gold.withValues(alpha: .55))),
      ),
      // [Sprint 72 R3] The dock always whole: its height shared between the crest and the sections, so none is cut or
      // hidden under a scroll on a phone 360 high (it was 50 + 7×54 = 428, with «More» out of sight). Under 340 the
      // sections lose their names.
      child: LayoutBuilder(
        builder: (context, box) {
          final crest = box.maxHeight < GlmFit.shortUnder ? 42.0 : 50.0;
          final each = ((box.maxHeight - crest) / sections.length).clamp(30.0, 54.0);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The club's crest: back to the office.
              Semantics(
                button: true,
                label: s?.club.name ?? l.navOffice,
                child: InkWell(
                  onTap: () => _go(context, base),
                  child: SizedBox(
                    height: crest,
                    child: Center(
                      child: ClubCrest(url: s?.club.crestUrl, name: s?.club.code ?? '', size: crest - 14),
                    ),
                  ),
                ),
              ),
              for (final x in sections)
                _DockItem(
                  section: x,
                  height: each,
                  on: x.entries.any((y) => _isOn(y.path)),
                  isOn: _isOn,
                  go: (path, push) => _go(context, path, push: push),
                ),
            ],
          );
        },
      ),
    );
  }

  bool _isOn(String path) {
    final base = '/leagues/$leagueId';
    if (path == base) return location == base || location == '$base?tab=club';
    return location == path || (!path.contains('?') && location.startsWith('$path/'));
  }

  void _go(BuildContext context, String path, {bool push = false}) {
    GameSounds.play(Sfx.tap);
    push ? context.push(path) : context.go(path);
  }
}

typedef _Section = ({GlmIcons icon, ({Color colour, bool dark})? tile, String label, List<_Entry> entries, String? badge});

/// [Sprint 63 G4] A dock tile's colour by its token's name (docs/design/nav.json), from the palette.
Color _tileColour(BuildContext context, String name) {
  final p = context.palette;
  return switch (name) {
    'gold' => p.gold,
    'brand' => p.brand,
    'ring' => p.ring,
    'live' => p.live,
    'warning' => p.warning,
    'brand-light' => p.brandLight,
    'chrome' => p.chrome,
    _ => p.surfaceRaised,
  };
}

/// An icon's file name (brand/icons/chevron_down.svg) as the app's name (GlmIcons.chevronDown).
String _camel(String name) {
  final parts = name.split('_');
  return parts.first + parts.skip(1).map((w) => w[0].toUpperCase() + w.substring(1)).join();
}

/// A section in the dock: its gold icon over its name; several pages open their list beside it.
class _DockItem extends StatelessWidget {
  const _DockItem({required this.section, required this.height, required this.on, required this.isOn, required this.go});

  final _Section section;

  /// The room the dock gives each section (54 at most; less on a short phone).
  final double height;
  final bool on;
  final bool Function(String path) isOn;
  final void Function(String path, bool push) go;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // The name under the icon while there is room for both; the tile shrinks first (26 to 20).
    final named = height >= 40;
    final tile = named ? (height - 22).clamp(20.0, 26.0) : (height - 8).clamp(20.0, 26.0);
    Widget item(VoidCallback onTap) => Semantics(
      button: true,
      selected: on,
      label: section.label,
      excludeSemantics: true,
      child: Material(
        color: on ? p.text.withValues(alpha: .06) : Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            height: height,
            decoration: BoxDecoration(
              border: BorderDirectional(end: BorderSide(color: on ? p.gold : Colors.transparent, width: 3)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // [Sprint 63 G4] On its section's tile, as the site's dock (AppShell.vue .dock-tile).
                    if (section.tile case final t?)
                      Container(
                        width: tile,
                        height: tile,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: t.colour,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [BoxShadow(color: GlmBroadcast.ink, blurRadius: 8, offset: Offset(0, 3), spreadRadius: -3)],
                        ),
                        child: GlmIcon(section.icon, size: 16, color: t.dark ? GlmBroadcast.ink : GlmBroadcast.white),
                      )
                    else
                      GlmIcon(section.icon, size: tile - 4, color: p.gold),
                    if (named)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          section.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: glmText(GlmType.caption, fontWeight: FontWeight.w800, height: 1.2, color: on ? p.goldLight : p.text),
                        ),
                      ),
                  ],
                ),
                if (section.badge == 'live') const PositionedDirectional(top: 4, end: 14, child: _LiveDot()),
              ],
            ),
          ),
        ),
      ),
    );
    if (section.entries.length == 1) {
      final x = section.entries.first;
      return item(() => go(x.path, x.push));
    }
    return MenuAnchor(
      alignmentOffset: Offset(4, -height),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(p.surface),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: p.gold.withValues(alpha: .3)),
          ),
        ),
      ),
      menuChildren: [
        for (final x in section.entries)
          MenuItemButton(
            onPressed: () => go(x.path, x.push),
            style: ButtonStyle(
              minimumSize: const WidgetStatePropertyAll(Size(200, 44)),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              backgroundColor: WidgetStatePropertyAll(isOn(x.path) ? p.brand : Colors.transparent),
              foregroundColor: WidgetStatePropertyAll(isOn(x.path) ? Colors.white : p.textSoft),
              textStyle: WidgetStatePropertyAll(glmText(GlmType.body, fontWeight: FontWeight.w700)),
            ),
            leadingIcon: GlmIcon(x.icon, size: 22),
            child: Text(x.label),
          ),
      ],
      builder: (context, controller, _) => item(() => controller.isOpen ? controller.close() : controller.open()),
    );
  }
}

/// The live match's pulsing red dot (the site's animate-pulse-ring on bg-live).
class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final live = context.palette.live;
    // [Sprint 65 F5] Less motion asked (or a widget test): the dot without its ripple.
    if (MediaQuery.disableAnimationsOf(context) || !Ambient.on) {
      _c.stop();
      return Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: live, shape: BoxShape.circle),
      );
    }
    if (!_c.isAnimating) unawaited(_c.repeat());
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: live,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: live.withValues(alpha: 1 - _c.value),
                spreadRadius: 6 * _c.value,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
