import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/theme.dart';
import '../../../ui/tokens.g.dart';
import '../../../ui/widgets/cut.dart';
import '../../../ui/widgets/game_icons.dart';
import '../../../ui/widgets/motion.dart';
import '../../club/club_data.dart';
import '../widgets.dart';

/// The hub's strip of tiles under the match, scrolling across when it does not fit.
class HubTiles extends StatelessWidget {
  const HubTiles({super.key, required this.s, required this.go, required this.table, this.contract, this.compact = false});

  final ClubSummary s;

  /// A phone held upright: two rows of four tiles.
  final bool compact;
  final void Function(String path) go;
  final VoidCallback table;

  /// The contract to sign (the board's goal), first in the strip while it waits.
  final VoidCallback? contract;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    bool needs(String kind) => s.needs.any((n) => n.kind == kind);
    final missing = needs('lineup');
    final prep = missing
        ? .35
        : s.lineupAuto
        ? .7
        : 1.0;
    DateTime? timer(String kind) => s.timers.where((t) => t.kind == kind).firstOrNull?.at;
    String left(DateTime? at) {
      if (at == null) return '';
      final d = at.difference(DateTime.now());
      if (d.isNegative) return '';
      final l = L.of(context);
      return d.inDays > 0 ? l.leftDays(d.inDays) : l.leftHoursMinutes(d.inHours, d.inMinutes % 60);
    }

    final table = _HubTile(
      onTap: this.table,
      icon: GameGlyph.table,
      title: l.leagueTable,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final r in s.top.take(3))
            Container(
              color: r.mine ? Colors.white.withValues(alpha: .08) : null,
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${r.position}',
                      style: TextStyle(
                        fontFamily: GlmFonts.numbers,
                        fontWeight: FontWeight.w800,
                        color: r.mine ? p.goldLight : Colors.white70,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      style: glmText(
                        GlmType.body,
                        fontFamily: GlmFonts.numbers,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: r.mine ? p.goldLight : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${r.points}',
                    style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: r.mine ? p.goldLight : Colors.white),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    // [Sprint 46, the owner's screenshots] Two rows under the match, filling the width as the manager games do: the
    // quick friendly, the match's preparation, training's clock and the form; then the quests (or the contract), the
    // market and the table.
    // [Sprint 47] On a phone, the approved design's office: four big tiles a row, each its icon over its name.
    if (compact) {
      final tiles = <Widget>[
        _HubTile(
          upright: true,
          alert: missing,
          onTap: () => go('lineup'),
          icon: GameGlyph.lineup,
          title: l.lineup,
          child: SizedBox(
            width: 56,
            child: _Progress(
              value: prep,
              color: missing
                  ? p.danger
                  : prep < 1
                  ? p.gold
                  : p.success,
            ),
          ),
        ),
        _HubTile(upright: true, onTap: () => go('tactics'), icon: GameGlyph.tactics, title: l.tactics),
        _HubTile(
          upright: true,
          alert: needs('training_empty') || needs('training_done'),
          onTap: () => go('training'),
          icon: GameGlyph.training,
          title: left(timer('training')).isEmpty ? l.training : left(timer('training')),
        ),
        _HubTile(upright: true, onTap: () => go('friendlies'), icon: GameGlyph.quick, title: l.friendlies),
        contract != null
            ? _HubTile(upright: true, gold: true, alert: true, onTap: contract!, icon: GameGlyph.contracts, title: l.sign)
            : _HubTile(upright: true, gold: true, onTap: () => go('quests'), icon: GameGlyph.quests, title: l.quests),
        _HubTile(upright: true, alert: needs('offers'), onTap: () => go('market'), icon: GameGlyph.transfers, title: l.market),
        _HubTile(upright: true, onTap: this.table, icon: GameGlyph.table, title: l.leagueTable),
        _HubTile(upright: true, onTap: () => go('stats'), icon: GameGlyph.honours, title: l.form, child: _Form(s.form)),
      ];
      return Column(
        children: [
          for (final r in [0, 4])
            Padding(
              padding: EdgeInsets.only(top: r == 0 ? 0 : 8),
              child: SizedBox(
                height: 92,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = r; i < r + 4; i++) ...[
                      if (i > r) const SizedBox(width: 8),
                      Expanded(
                        child: FadeSlideIn(index: i, child: tiles[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      );
    }
    Widget row(List<(int, Widget)> xs) => Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, (flex, w)) in xs.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            flex: flex,
            child: FadeSlideIn(index: i, child: w),
          ),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        children: [
          Expanded(
            child: row([
              (5, _HubTile(onTap: () => go('friendlies'), icon: GameGlyph.quick, title: l.quickFriendly, sub: l.quickFriendlySub)),
              (
                5,
                _HubTile(
                  alert: missing,
                  onTap: () => go('lineup'),
                  icon: GameGlyph.lineup,
                  title: l.matchPrep,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        missing
                            ? l.prepMissing
                            : s.lineupAuto
                            ? l.prepAuto
                            : l.prepReady,
                        style: glmText(GlmType.caption, color: missing ? p.danger : Colors.white70, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      _Progress(
                        value: prep,
                        color: missing
                            ? p.danger
                            : prep < 1
                            ? p.gold
                            : p.success,
                      ),
                    ],
                  ),
                ),
              ),
              (
                3,
                _HubTile(
                  upright: true,
                  alert: needs('training_empty') || needs('training_done'),
                  onTap: () => go('training'),
                  icon: GameGlyph.training,
                  title: left(timer('training')).isEmpty ? l.training : left(timer('training')),
                ),
              ),
              (3, _HubTile(upright: true, onTap: () => go('stats'), icon: GameGlyph.honours, title: l.form, child: _Form(s.form))),
            ]),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: row([
              (
                3,
                contract != null
                    ? _HubTile(
                        gold: true,
                        alert: true,
                        onTap: contract!,
                        icon: GameGlyph.contracts,
                        title: l.sign,
                        sub: goalText(l, s.goal),
                      )
                    : _HubTile(
                        gold: true,
                        onTap: () => go('quests'),
                        icon: GameGlyph.quests,
                        title: l.quests,
                        sub: left(timer('daily')).isEmpty ? l.questsSub : left(timer('daily')),
                      ),
              ),
              (
                5,
                _HubTile(
                  alert: needs('offers'),
                  onTap: () => go('market'),
                  icon: GameGlyph.transfers,
                  title: l.market,
                  sub: left(timer('market')).isEmpty ? l.subMarket : '${l.marketRenews} ${left(timer('market'))}',
                ),
              ),
              (5, table),
            ]),
          ),
        ],
      ),
    );
  }
}

/// The club's last results as five lit squares (W green, D grey, L red), newest at the reading end.
class _Form extends StatelessWidget {
  const _Form(this.form);

  final List<String> form;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final last = form.length > 5 ? form.sublist(form.length - 5) : form;
    if (last.isEmpty) {
      return Text(
        '—',
        style: TextStyle(color: p.textMuted, fontWeight: FontWeight.w800),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final r in last)
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              shape: GlmCut.shape(5),
              color: r == 'W'
                  ? p.success
                  : r == 'L'
                  ? p.live
                  : p.textMuted,
            ),
            child: Text(
              {'W': L.of(context).formWin, 'D': L.of(context).formDraw, 'L': L.of(context).formLoss}[r] ?? r,
              style: glmText(GlmType.caption, color: Colors.white, fontWeight: FontWeight.w900, height: 1),
            ),
          ),
      ],
    );
  }
}

/// A tile of the hub: a navy card lit from the top (gold for the quests), its glossy icon, its title in gold, a line or
/// its own content, and the green «!» when it needs the coach.
class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.onTap,
    required this.icon,
    required this.title,
    this.sub,
    this.child,
    this.alert = false,
    this.gold = false,
    this.upright = false,
  });

  /// The icon over the title, centred (the small tiles: training, the form).
  final bool upright;
  final VoidCallback onTap;
  final GameGlyph icon;
  final String title;
  final String? sub;
  final Widget? child;
  final bool alert, gold;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final card = Material(
      shape: GlmCut.shape(15, side: BorderSide(color: gold ? p.goldLight : GlmStage.edge)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gold ? [GlmStage.questTop, GlmStage.questBottom] : [GlmStage.card, GlmStage.card],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          child: upright
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: FittedBox(fit: BoxFit.scaleDown, child: GameIcon(icon, size: 44)),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        maxLines: 1,
                        style: glmText(
                          GlmType.body,
                          fontFamily: GlmFonts.body,
                          color: gold ? p.onGold : Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (child != null) ...[const SizedBox(height: 3), FittedBox(fit: BoxFit.scaleDown, child: child)],
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GameIcon(icon, size: 46),
                    const SizedBox(width: 10),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, c) => FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: SizedBox(
                            width: c.maxWidth,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: glmText(GlmType.bodyLg, color: gold ? p.onGold : p.goldLight, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 3),
                                ?child,
                                if (sub != null)
                                  Text(
                                    sub!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: glmText(
                                      GlmType.caption,
                                      color: gold ? p.onGold.withValues(alpha: .8) : Colors.white70,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        PressScale(child: card),
        if (alert)
          PositionedDirectional(
            top: -6,
            start: 8,
            child: Pulse(
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GlmStage.alert,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                ),
                child: Text(
                  '!',
                  style: glmText(GlmType.body, color: Colors.white, fontWeight: FontWeight.w900, height: 1),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: 14,
    padding: const EdgeInsets.all(2),
    decoration: ShapeDecoration(
      shape: GlmCut.shape(5, side: BorderSide(color: Colors.white.withValues(alpha: .25))),
      color: Colors.black.withValues(alpha: .45),
    ),
    child: FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: value.clamp(0, 1),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: GlmCut.shape(3),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(color, Colors.white, .3)!, color],
          ),
        ),
      ),
    ),
  );
}
