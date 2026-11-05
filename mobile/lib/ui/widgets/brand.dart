import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme.dart';
import '../tokens.g.dart';

/// [Sprint 15 F2] The game's mark as on the web (BrandMark.vue): the crest, GAME LEGEND MANAGER with MANAGER in gold,
/// and «المدرب الأسطورة» under it in Arabic.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44, this.stacked = false});

  final double size;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final p = context.palette;
    final name = Text.rich(
      TextSpan(children: [
        TextSpan(text: 'GAME LEGEND ', style: TextStyle(color: p.text)),
        TextSpan(text: 'MANAGER', style: TextStyle(color: context.glm.goldText)),
      ]),
      textDirection: TextDirection.ltr,
      style: TextStyle(fontFamily: GlmFonts.body, fontWeight: FontWeight.w800, letterSpacing: stacked ? 3 : 1, fontSize: stacked ? 22 : 14),
    );
    final sub = Text(ar ? 'المدرب الأسطورة' : 'ONLINE FOOTBALL MANAGER',
        style: TextStyle(fontSize: stacked ? 15 : 10, fontWeight: FontWeight.w700, color: p.textSoft, letterSpacing: ar ? 0 : 2));
    final crest = Image.asset(ar ? 'assets/brand/emblem-ar.png' : 'assets/brand/emblem.png', width: size, height: size, semanticLabel: 'Game Legend Manager');
    if (stacked) {
      return Column(mainAxisSize: MainAxisSize.min, children: [crest, const SizedBox(height: 14), name, const SizedBox(height: 4), sub]);
    }
    // In a bar beside other buttons, the name shrinks to the room left rather than overflow.
    return Row(mainAxisSize: MainAxisSize.min, children: [
      crest,
      const SizedBox(width: 10),
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [name, sub]),
        ),
      ),
    ]);
  }
}

/// The coins pill of the bar: the coin and the balance in the numbers' font.
class CoinsPill extends StatelessWidget {
  const CoinsPill({super.key, required this.coins, this.onTap});

  final int coins;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.gold.withValues(alpha: .16),
      shape: StadiumBorder(side: BorderSide(color: p.gold.withValues(alpha: .4))),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GlmSize.touchMin),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Image.asset('assets/brand/coin.png', width: 22, height: 22),
              const SizedBox(width: 6),
              Text('$coins', style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 18, color: context.glm.goldText)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// A club's crest from the API (an SVG), with its code while it loads or when it cannot.
class ClubCrest extends StatelessWidget {
  const ClubCrest({super.key, required this.url, required this.name, this.size = 44});

  final String? url;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final initials = Container(
      width: size, height: size, alignment: Alignment.center,
      decoration: BoxDecoration(color: p.surfaceRaised, shape: BoxShape.circle),
      child: Text(name.characters.take(2).toString(), style: TextStyle(fontWeight: FontWeight.w800, color: p.textSoft, fontSize: size * .32)),
    );
    if (url == null) return initials;
    return SvgPicture.network(url!, width: size, height: size, placeholderBuilder: (_) => initials, semanticsLabel: name);
  }
}
