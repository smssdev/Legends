import '../../ui/tokens.g.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../club/squad_screen.dart' show money;
import 'market_data.dart';
import '../leagues/shell.dart';

/// [Sprint 18 D] An offer to another coach (Sprint 25): his players I ask for, mine I give, and the money; or my
/// counter to his offer (counterOf), its players already chosen; or, for one of his players alone, a loan (X61 E2).
/// The server checks the deal (its fair range, the pair's cap, the window) and says why when it refuses.
class OfferScreen extends ConsumerStatefulWidget {
  const OfferScreen({
    super.key,
    required this.leagueId,
    required this.clubId,
    required this.clubName,
    this.counterOf,
    this.want = const {},
    this.give = const {},
    this.fairMinBp = 5000,
    this.fairMaxBp = 20000,
  });

  final int leagueId, clubId;
  final String clubName;
  final int? counterOf;
  final Set<int> want, give;
  final int fairMinBp, fairMaxBp;

  @override
  ConsumerState<OfferScreen> createState() => _OfferScreenState();
}

final _theirPlayers = FutureProvider.autoDispose.family((ref, (int, int) k) => ref.read(marketRepositoryProvider).clubPlayers(k.$1, k.$2));

class _OfferScreenState extends ConsumerState<OfferScreen> {
  late final Set<int> _want = {...widget.want};
  late final Set<int> _give = {...widget.give};
  final _money = TextEditingController(text: '0');
  double _rounds = 3;
  final _fee = TextEditingController(text: '0');
  bool _busy = false;

  @override
  void dispose() {
    _money.dispose();
    _fee.dispose();
    super.dispose();
  }

  int _parse(TextEditingController c) => int.tryParse(c.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  Future<void> _send(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        showGlmToast(context, done);
        Navigator.pop(context, true);
      }
    } on ApiError catch (e) {
      if (mounted) showGlmToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final repo = ref.read(marketRepositoryProvider);
    final mine = ref.watch(sellingProvider(widget.leagueId)).value?.mine ?? const <MyPlayer>[];
    final loanTerms = ref.watch(loansProvider(widget.leagueId)).value;
    return Scaffold(
      appBar: GameBar(title: Text(widget.counterOf != null ? l.counterOffer : l.offerTitleTo(widget.clubName))),
      body: GlmBackground(
        child: AsyncView(
          value: ref.watch(_theirPlayers((widget.leagueId, widget.clubId))),
          onRetry: () => ref.invalidate(_theirPlayers((widget.leagueId, widget.clubId))),
          data: (theirs) {
            final wantValue = theirs.where((x) => _want.contains(x.id)).fold<int>(0, (a, x) => a + x.value);
            final giveValue = mine.where((x) => _give.contains(x.id)).fold<int>(0, (a, x) => a + x.value) + _parse(_money);
            Widget pick(String name, String sub, bool on, VoidCallback tap) => CheckboxListTile(
              dense: true,
              value: on,
              activeColor: p.gold,
              contentPadding: EdgeInsets.zero,
              title: Text(
                name,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.start,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(sub, textDirection: TextDirection.ltr, textAlign: TextAlign.start),
              onChanged: (_) => setState(tap),
            );
            final onlyOne = _want.length == 1 && _give.isEmpty && _parse(_money) == 0 && widget.counterOf == null;
            final summary = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.offerValues(money(context, wantValue), money(context, giveValue)),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  l.fairHint(widget.fairMinBp ~/ 100, widget.fairMaxBp ~/ 100),
                  textAlign: TextAlign.center,
                  style: glmText(GlmType.caption, color: p.textMuted),
                ),
                const SizedBox(height: 8),
                GlmButton(
                  label: l.sendOffer,
                  block: true,
                  loading: _busy,
                  onPressed: _want.isEmpty
                      ? null
                      : () => _send(
                          () => repo.offer(
                            widget.leagueId,
                            to: widget.counterOf == null ? widget.clubId : null,
                            counterOf: widget.counterOf,
                            money: _parse(_money),
                            want: _want.toList(),
                            give: _give.toList(),
                          ),
                          l.offerSent,
                        ),
                ),
              ],
            );
            // The terms scroll; what they add up to and «send» stay at the bottom.
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      TextField(
                        controller: _money,
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(labelText: l.youPay),
                        onChanged: (_) => setState(() {}),
                      ),
                      if (onlyOne && loanTerms != null) ...[
                        const SizedBox(height: 12),
                        GlmCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(l.loanRounds(_rounds.round()), style: const TextStyle(fontWeight: FontWeight.w700)),
                              Slider(
                                value: _rounds,
                                min: 1,
                                max: loanTerms.maxRounds.toDouble(),
                                divisions: (loanTerms.maxRounds - 1).clamp(1, 20),
                                activeColor: p.gold,
                                onChanged: (v) => setState(() => _rounds = v),
                              ),
                              TextField(
                                controller: _fee,
                                keyboardType: TextInputType.number,
                                textDirection: TextDirection.ltr,
                                decoration: InputDecoration(labelText: l.loanFee),
                              ),
                              const SizedBox(height: 10),
                              GlmButton(
                                label: l.askLoan,
                                variant: GlmButtonVariant.outline,
                                onPressed: _busy
                                    ? null
                                    : () => _send(
                                        () => repo.askLoan(widget.leagueId, _want.first, _rounds.round(), _parse(_fee)),
                                        l.loanSent,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SectionTitle(l.youWant),
                      GlmCard(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Column(
                          children: [
                            for (final x in theirs)
                              pick(
                                x.name,
                                '${x.position} · ${x.overall} · ${money(context, x.value)}',
                                _want.contains(x.id),
                                () => _want.contains(x.id) ? _want.remove(x.id) : (_want.length < 5 ? _want.add(x.id) : null),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SectionTitle(l.youGive),
                      GlmCard(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Column(
                          children: [
                            for (final x in mine)
                              pick(
                                x.name,
                                '${x.position} · ${x.overall} · ${money(context, x.value)}',
                                _give.contains(x.id),
                                () => _give.contains(x.id) ? _give.remove(x.id) : (_give.length < 5 ? _give.add(x.id) : null),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                Material(
                  color: p.surface,
                  elevation: 8,
                  child: SafeArea(
                    top: false,
                    child: Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 10), child: summary),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
