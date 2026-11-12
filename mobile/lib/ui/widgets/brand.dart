import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/config.dart';

import '../theme.dart';
import '../tokens.g.dart';
import 'cut.dart';
import 'kit.dart';
import 'legend_crest.dart';

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
      TextSpan(
        children: [
          TextSpan(
            text: 'GAME LEGEND ',
            style: TextStyle(color: p.text),
          ),
          TextSpan(
            text: 'MANAGER',
            style: TextStyle(color: context.glm.goldText),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
      style: TextStyle(
        fontFamily: GlmFonts.numbers,
        fontWeight: FontWeight.w700,
        letterSpacing: stacked ? 2 : 1,
        fontSize: stacked ? 26 : 16,
      ),
    );
    final sub = Text(
      ar ? 'المدرب الأسطورة' : 'ONLINE FOOTBALL MANAGER',
      style: TextStyle(fontSize: stacked ? 15 : 10, fontWeight: FontWeight.w700, color: p.textSoft, letterSpacing: ar ? 0 : 2),
    );
    // [Sprint 47] The approved design's crest, drawn (legend_crest.dart), as tall as [size].
    final crest = LegendCrest(size: size * 150 / 172, letters: size >= 56);
    if (stacked) {
      return Column(mainAxisSize: MainAxisSize.min, children: [crest, const SizedBox(height: 14), name, const SizedBox(height: 4), sub]);
    }
    // In a bar beside other buttons, the name shrinks to the room left rather than overflow.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        crest,
        const SizedBox(width: 10),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [name, sub]),
          ),
        ),
      ],
    );
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
      shape: GlmCut.shape(GlmCut.button, side: BorderSide(color: p.gold.withValues(alpha: .45))),
      child: InkWell(
        customBorder: GlmCut.shape(GlmCut.button),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GlmSize.touchMin),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/brand/coin.png', width: 22, height: 22),
                const SizedBox(width: 6),
                Text(
                  '$coins',
                  style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 18, color: context.glm.goldText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A club's crest from the API (an SVG), with a drawn shield and its code while it loads or when it cannot.
class ClubCrest extends StatelessWidget {
  const ClubCrest({super.key, required this.url, required this.name, this.size = 44, this.color});

  /// Off in the widget tests, which never reach the network.
  static bool loadFromNetwork = true;

  final String? url;
  final String name;
  final double size;

  /// The club's colour for the drawn shield, when known.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final shield = CrestShield(code: name, color: color, size: size);
    if (url == null || !loadFromNetwork) return shield;
    // [Sprint 46] The club's real logo, as the site shows it: the crest address answers with the imported picture
    // (/logos/....webp, ClubLogo) where the club has one, else with its drawn badge (SVG). The picture first, the SVG
    // when it is not one, our shield while either loads.
    final full = url!.startsWith('/') ? '${AppConfig.siteUrl}$url' : url!;
    return Image.network(
      full,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: name,
      loadingBuilder: (_, child, progress) => progress == null ? child : shield,
      errorBuilder: (_, _, _) =>
          SvgPicture.network(full, width: size, height: size, placeholderBuilder: (_) => shield, semanticsLabel: name),
    );
  }
}
