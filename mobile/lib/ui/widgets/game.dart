import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.g.dart';
import 'glm_card.dart';

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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .28),
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(bg, Colors.white, .18)!, bg]),
        boxShadow: [BoxShadow(color: bg.withValues(alpha: .35), blurRadius: 10, offset: const Offset(0, 4), spreadRadius: -4)],
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
      decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(7)),
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: (color ?? p.gold).withValues(alpha: .16), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 20, color: color ?? p.gold),
          ),
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
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
        child: Row(children: [
          if (icon != null) ...[Icon(icon, size: 18, color: context.palette.gold), const SizedBox(width: 6)],
          Expanded(child: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: context.palette.text))),
          ?trailing,
        ]),
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
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [(m.color ?? p.gold).withValues(alpha: .30), (m.color ?? p.gold).withValues(alpha: .12)]),
                    ),
                    child: Icon(m.icon, size: 21, color: m.color ?? p.gold),
                  ),
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
                      decoration: BoxDecoration(color: p.live, borderRadius: BorderRadius.circular(99)),
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
