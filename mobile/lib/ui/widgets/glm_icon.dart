import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../art_palette.dart';
import '../theme.dart';
import 'glm_icons.g.dart';

export 'glm_icons.g.dart';

/// [Sprint 63 G3] One of the game's line icons, the site's same drawing (brand/icons, tools/brand/icons.py): a 24 grid
/// stroked in [color] (the icon theme's by default).
class GlmIcon extends StatelessWidget {
  const GlmIcon(this.icon, {super.key, this.size, this.color, this.label});

  final GlmIcons icon;
  final double? size;
  final Color? color;

  /// What a screen reader says; none for an icon beside its words.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final side = size ?? theme.size ?? 24;
    final svg = SvgPicture.string(
      '<svg viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="$glmIconStroke" stroke-linecap="round" '
      'stroke-linejoin="round"><path d="${icon.path}"/></svg>',
      width: side,
      height: side,
      colorFilter: ColorFilter.mode(color ?? theme.color ?? Colors.white, BlendMode.srcIn),
    );
    return label == null ? ExcludeSemantics(child: svg) : Semantics(label: label, image: true, child: svg);
  }
}

/// [Sprint 63 G5] A match event's mark (the commentary, a recap, a player's state), an icon of the set in its colour,
/// where an emoji stood: the ball, a card, a substitution, an injury, a penalty, a corner, a save, the clock.
class GlmEventMark extends StatelessWidget {
  const GlmEventMark(this.kind, {super.key, this.size = 16});

  /// The event's type as the server names it (goal, card, yellow, red, sub, injury, penalty, corner, saved, period),
  /// with a card's colour in [kind] when it is known (yellow, red).
  final String kind;
  final double size;

  static (GlmIcons, Color?) of(String kind, BuildContext context) {
    final p = context.palette;
    return switch (kind) {
      'goal' => (GlmIcons.ball, null),
      'yellow' || 'card' => (GlmIcons.card, GlmArt.yellowCard),
      'red' => (GlmIcons.card, GlmArt.redCard),
      'sub' => (GlmIcons.swap, p.brandLight),
      'injury' => (GlmIcons.injury, p.danger),
      'penalty' => (GlmIcons.target, null),
      'corner' => (GlmIcons.corner, null),
      'saved' => (GlmIcons.glove, null),
      'period' => (GlmIcons.clock, null),
      _ => (GlmIcons.dot, p.textMuted),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = of(kind, context);
    return GlmIcon(icon, size: size, color: color ?? DefaultTextStyle.of(context).style.color);
  }
}

/// [Sprint 63 G5] A title's place (the honours, a coach's trophies): the trophy for the first, a medal in silver or
/// bronze for the next two.
class GlmPlaceMark extends StatelessWidget {
  const GlmPlaceMark(this.position, {super.key, this.size = 26});

  final int position;
  final double size;

  @override
  Widget build(BuildContext context) => position == 1
      ? GlmIcon(GlmIcons.trophy, size: size, color: context.palette.gold)
      : GlmIcon(GlmIcons.medal, size: size, color: position == 2 ? GlmArt.silver : GlmArt.bronze);
}

/// [Sprint 63 G5] A rating in stars (a specialist's level): the set's star, [count] of them.
class GlmStars extends StatelessWidget {
  const GlmStars(this.count, {super.key, this.size = 16, this.color});

  final int count;
  final double size;
  final Color? color;

  @override
  // A Wrap: in a narrow place the stars go on to a second line, as their text did.
  Widget build(BuildContext context) => Wrap(
    children: [for (var i = 0; i < count; i++) GlmIcon(GlmIcons.star, size: size, color: color ?? context.palette.gold)],
  );
}
