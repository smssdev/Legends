import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.g.dart';

/// [Sprint 60 F4] A player's name under his place on the pitch, as the approved drafts draw it (Lineup.html,
/// Tactics.html: the `.pl` label, cut with «…» past its width). The pitch's places are too close for every long name on
/// a phone, so this one label may end in «…»: the name is whole in the bench column, the squad and the player's card.
/// The screenshots' cut-text check (test/shots) leaves these labels out, and only these.
class PitchName extends StatelessWidget {
  const PitchName(this.name, {super.key, this.width = 64});

  final String name;
  final double width;

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(maxWidth: width),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(color: Colors.black.withValues(alpha: .55), borderRadius: BorderRadius.circular(GlmRadius.sm)),
    child: Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textDirection: TextDirection.ltr,
      style: glmText(GlmType.caption, color: Colors.white, fontWeight: FontWeight.w700, height: 1.2, decoration: TextDecoration.none),
    ),
  );
}
