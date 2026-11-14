import 'package:flutter/material.dart';

import '../../api/gen/models.g.dart' as api;
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../club/squad_screen.dart' show money;
import 'widgets.dart' show when;

/// [Sprint 64 F-B4] A spend before it is made, as the server quotes it (App\Wallet\SpendQuote): what is left after,
/// and when what it buys ends. One line under the spend's button, on every screen that spends (as on the site).
class SpendNote extends StatelessWidget {
  const SpendNote(this.quote, {super.key});

  final api.SpendQuote quote;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    String amount(int v) => quote.currency == 'coins' ? l.coinsWord(v) : money(context, v);
    final ends = DateTime.tryParse(quote.endsAt ?? '');
    final text = [
      quote.can ? l.spendLeft(amount(quote.after)) : l.spendShort(amount(-quote.after)),
      if (ends != null) l.spendEnds(when(context, ends.toLocal())),
    ].join(' · ');
    return Text(text, style: glmText(GlmType.caption, color: quote.can ? context.palette.textMuted : context.glm.liveText));
  }
}
