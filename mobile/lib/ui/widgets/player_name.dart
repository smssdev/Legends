import 'package:flutter/material.dart';

/// [Sprint 72 R6] A player's name on one line, in the room it is given: whole if it fits, else its first name as an
/// initial («G. Mamardashvili»), else the last name alone, and only then a size smaller (down to 12) before it is cut.
/// Never broken inside a word («Giorg/i M…» on a 640 phone). Names stay in English in every language (2026-11-01).
class PlayerName extends StatelessWidget {
  const PlayerName(this.name, {super.key, this.style, this.textAlign});

  final String name;
  final TextStyle? style;
  final TextAlign? textAlign;

  /// The forms to try, longest first. Pure.
  static List<String> forms(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return [name.trim()];
    final last = parts.sublist(1).join(' ');
    return [name.trim(), '${parts.first[0]}. $last', parts.last];
  }

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(style);
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        var text = name, size = base.fontSize ?? 14;
        if (box.maxWidth.isFinite) {
          bool fits(String t, double s) {
            final tp = TextPainter(
              text: TextSpan(
                text: t,
                style: base.copyWith(fontSize: s),
              ),
              textDirection: TextDirection.ltr,
              textScaler: scaler,
              maxLines: 1,
            )..layout();
            final ok = tp.width <= box.maxWidth;
            tp.dispose();
            return ok;
          }

          final all = forms(name);
          text = all.firstWhere((t) => fits(t, size), orElse: () => all.last);
          while (size > 12 && !fits(text, size)) {
            size -= 1;
          }
        }
        return Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textDirection: TextDirection.ltr,
          textAlign: textAlign,
          style: base.copyWith(fontSize: size),
        );
      },
    );
  }
}
