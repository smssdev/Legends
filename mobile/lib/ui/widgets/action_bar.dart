import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../tokens.g.dart';

/// [Sprint 60 F7] One place for a screen's actions: a strip along the bottom of the screen, each action its icon over
/// its name (no circle without a name, M-D07), and the main one, gold, at its end. The same place on every screen, so a
/// coach never looks for a button in the corners again (M-D08). Its height is [GlmActionBar.height]: what floats over the
/// screen above it keeps clear of it.
class GlmActionBar extends StatelessWidget {
  const GlmActionBar({super.key, required this.actions, this.main});

  /// The actions, start to end (a [GlmActionItem] each, or one inside a menu button).
  final List<Widget> actions;

  /// The main action at the end (a GlmButton).
  final Widget? main;

  static const double height = 60;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: GlmSpace.sm),
      decoration: BoxDecoration(
        color: p.bgDeep.withValues(alpha: .82),
        border: Border(top: BorderSide(color: p.gold.withValues(alpha: .2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: actions),
            ),
          ),
          if (main != null) ...[const SizedBox(width: GlmSpace.sm), main!],
        ],
      ),
    );
  }
}

/// One action of the bar: its icon over its name, 48 wide at least (the touch target), lit when [on].
class GlmActionItem extends StatelessWidget {
  const GlmActionItem({super.key, required this.icon, required this.label, this.onTap, this.on = false});

  final Widget icon;
  final String label;

  /// Null inside a menu button (the menu takes the tap) or when it cannot be used now.
  final VoidCallback? onTap;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: GlmTouch.app, minHeight: GlmActionBar.height - 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: GlmSpace.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme(
              data: IconThemeData(color: on ? p.gold : p.text, size: 24),
              child: SizedBox(height: 26, child: Center(child: icon)),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              style: glmText(GlmType.caption, color: on ? p.gold : p.text, fontWeight: FontWeight.w700, height: 1.1),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      button: true,
      selected: on,
      label: label,
      excludeSemantics: true,
      child: onTap == null
          ? content
          : InkWell(
              borderRadius: BorderRadius.circular(GlmRadius.md),
              onTap: () {
                HapticFeedback.selectionClick();
                onTap!();
              },
              child: content,
            ),
    );
  }
}
