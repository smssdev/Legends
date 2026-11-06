import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.g.dart';
import 'cut.dart';
import 'glm_card.dart';
import 'motion.dart';
import '../../features/leagues/shell.dart';

/// [2026-11-06] The game's shared pieces for every screen: a rating badge coloured by its level, a stat tile, a
/// section header, and grouped menus of screens (an icon in its colour, a title and a line), in place of walls of tiles.

/// A player's rating as a badge: gold from 85, green from 75, blue from 65, grey below.
class RatingBadge extends StatelessWidget {
  const RatingBadge(this.value, {super.key, this.size = 40});

  final int value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (bg, fg) = value >= 85
        ? (p.gold, p.onGold)
        : value >= 75
            ? (p.success, Colors.white)
            : value >= 65
                ? (GlmLine.def.bg, Colors.white)
                : (p.surfaceRaised, p.text);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      // In the Legend Cut, lit from the top like a medal.
      decoration: ShapeDecoration(
        shape: GlmCut.shape(size * .26, side: BorderSide(color: Colors.white.withValues(alpha: .22))),
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(bg, Colors.white, .28)!, bg, Color.lerp(bg, Colors.black, .12)!], stops: const [0, .55, 1]),
        shadows: [BoxShadow(color: bg.withValues(alpha: .40), blurRadius: 12, offset: const Offset(0, 4), spreadRadius: -4)],
      ),
      child: Text('$value', style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: size * .5, fontWeight: FontWeight.w800, color: fg, height: 1)),
    );
  }
}

/// A position as a small chip in its line's colour.
class PositionChip extends StatelessWidget {
  const PositionChip(this.position, this.line, {super.key});

  final String position, line;

  @override
  Widget build(BuildContext context) {
    final c = switch (line) { 'gk' => GlmLine.gk, 'def' => GlmLine.def, 'mid' => GlmLine.mid, _ => GlmLine.att };
    return Container(
      constraints: const BoxConstraints(minWidth: 38),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: ShapeDecoration(color: c.bg, shape: GlmCut.shape(GlmCut.chip)),
      child: Text(position, textAlign: TextAlign.center, textDirection: TextDirection.ltr,
          style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 14, color: c.fg, height: 1.1)),
    );
  }
}

/// A thin bar for fitness or progress, coloured by how full it is (unless a colour is given).
class LevelBar extends StatelessWidget {
  const LevelBar(this.value, {super.key, this.color, this.width = 46, this.height = 5});

  /// 0..1.
  final double value;
  final Color? color;
  final double width, height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final v = value.clamp(0, 1).toDouble();
    final c = color ?? (v >= .8 ? p.success : v >= .6 ? p.warning : p.danger);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: p.surfaceSunk, borderRadius: BorderRadius.circular(height)),
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(widthFactor: v, child: Container(decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(height)))),
    );
  }
}

/// A number with its label (a position, the coins, a value): big digits, a small caption.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label, this.icon, this.color});

  final String value, label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlmCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(children: [
        if (icon != null) ...[
          IconTile(icon!, color: color ?? p.gold, size: 36),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, textDirection: TextDirection.ltr, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: GlmFonts.numbers, fontFamilyFallback: const [GlmFonts.body], fontSize: 22, fontWeight: FontWeight.w800, color: p.text, height: 1.1)),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.textMuted, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }
}

/// A section's title over its content, with an optional action at the end.
class GameHeader extends StatelessWidget {
  const GameHeader(this.title, {super.key, this.trailing, this.icon});

  final String title;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 18, 2, 10),
        child: BroadcastTitle(title, icon: icon, trailing: trailing),
      );
}

/// One screen in a menu: its icon in a coloured square, its name, a short line, and a badge (a count waiting).
class MenuItem {
  const MenuItem(this.icon, this.title, this.onTap, {this.subtitle, this.color, this.badge});

  final IconData icon;
  final String title;
  final String? subtitle, badge;
  final Color? color;
  final VoidCallback onTap;
}

/// Screens grouped under a title in one card: a list, easy to scan and to reach with a thumb.
class MenuSection extends StatelessWidget {
  const MenuSection({super.key, required this.title, required this.items, this.icon});

  final String title;
  final IconData? icon;
  final List<MenuItem> items;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GameHeader(title, icon: icon),
      GlmCard(
        padding: EdgeInsets.zero,
        child: Column(children: [
          for (final (i, m) in items.indexed) ...[
            if (i > 0) Divider(height: 1, indent: 64, color: Colors.white.withValues(alpha: context.glm.day ? 0 : .06)),
            InkWell(
              onTap: m.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  IconTile(m.icon, color: m.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      if (m.subtitle != null) Text(m.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.textMuted, fontSize: 12)),
                    ]),
                  ),
                  if (m.badge != null)
                    Container(
                      margin: const EdgeInsetsDirectional.only(end: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: ShapeDecoration(color: p.live, shape: GlmCut.shape(GlmCut.chip + 2)),
                      child: Text(m.badge!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                  Icon(Icons.chevron_right_rounded, color: p.textMuted),
                ]),
              ),
            ),
          ],
        ]),
      ),
    ]);
  }
}

/// [2026-11-06] A screen in two columns on a wide (landscape) screen, each scrolling on its own, or one list when narrow.
/// Each child arrives with a short staggered rise.
class GamePanes extends StatelessWidget {
  const GamePanes({super.key, required this.start, required this.end, this.startFlex = 5, this.endFlex = 4, this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 24)});

  final List<Widget> start, end;
  final int startFlex, endFlex;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        List<Widget> rise(List<Widget> xs, int from) => [for (final (i, w) in xs.indexed) FadeSlideIn(index: from + i, child: w)];
        if (box.maxWidth < 560) return ListView(padding: padding, children: rise([...start, ...end], 0));
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: startFlex, child: ListView(padding: padding.copyWith(right: padding.right / 2), children: rise(start, 0))),
          Expanded(flex: endFlex, child: ListView(padding: padding.copyWith(left: padding.left / 2), children: rise(end, 2))),
        ]);
      });
}

/// [2026-11-06, stage 3] Cards in as many columns as fit ([minWidth] each), one under the other when narrow, each
/// arriving with a short staggered rise.
class GameGrid extends StatelessWidget {
  const GameGrid({super.key, required this.children, this.minWidth = 340, this.spacing = 10, this.maxColumns = 3});

  final List<Widget> children;
  final double minWidth, spacing;
  final int maxColumns;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final cols = (box.maxWidth / minWidth).floor().clamp(1, maxColumns);
        final w = (box.maxWidth - (cols - 1) * spacing) / cols;
        return Wrap(spacing: spacing, runSpacing: spacing, children: [
          for (final (i, c) in children.indexed) SizedBox(width: w, child: FadeSlideIn(index: i, child: c)),
        ]);
      });
}

/// An icon on a glossy square in its colour: the game's icon style everywhere (menus, rails, headers, empty states).
class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.color, this.size = 38});

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.palette.gold;
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        shape: GlmCut.shape(size * .30, side: BorderSide(color: c.withValues(alpha: .30))),
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c.withValues(alpha: .36), c.withValues(alpha: .10)]),
      ),
      child: Icon(icon, size: size * .55, color: c),
    );
  }
}

/// True on a wide (landscape) screen: the layouts that sit side by side.
bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 640;

/// [2026-11-06, stage 3] A screen's bar with its tabs: under the title on a narrow screen, and beside it on a wide one,
/// where every row of height counts (a phone in landscape is about 390 points tall).
PreferredSizeWidget gameTabsBar(BuildContext context, {required String title, required List<Tab> tabs, List<Widget>? actions}) {
  final p = context.palette;
  final bar = TabBar(
    tabs: tabs,
    isScrollable: isWide(context),
    tabAlignment: isWide(context) ? TabAlignment.center : null,
    indicatorColor: p.gold,
    indicatorWeight: 3,
    labelColor: context.glm.goldText,
    unselectedLabelColor: p.textSoft,
    labelStyle: const TextStyle(fontFamily: GlmFonts.body, fontWeight: FontWeight.w800, fontSize: 15),
    unselectedLabelStyle: const TextStyle(fontFamily: GlmFonts.body, fontWeight: FontWeight.w600, fontSize: 15),
    dividerColor: Colors.transparent,
  );
  if (!isWide(context)) return GameBar(title: Text(title), actions: actions, bottom: bar);
  return GameBar(
    titleSpacing: 16,
    title: Row(children: [Text(title), const SizedBox(width: 16), Expanded(child: bar)]),
    actions: actions,
  );
}
