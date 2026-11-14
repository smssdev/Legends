import '../../ui/tokens.g.dart';

import '../leagues/spend_note.dart';

import 'dart:async';

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
import 'finance_screen.dart' show confirm;
import 'money_data.dart';
import '../console/store_console.dart';
import '../leagues/shell.dart';

/// [Sprint 18 F1] The stadium (the web's StadiumPage, Sprint 29): seats, pitch and training, three stages of five
/// parts each, one part at a time. The coach starts each part and pays for it; the server times it from the league's
/// length (Sprint 43 C4) and may finish it now for coins.
class StadiumScreen extends ConsumerStatefulWidget {
  const StadiumScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  ConsumerState<StadiumScreen> createState() => _StadiumScreenState();
}

class _StadiumScreenState extends ConsumerState<StadiumScreen> {
  StadiumView? _fresh;
  bool _busy = false;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<StadiumView> Function() action) async {
    setState(() => _busy = true);
    try {
      final v = await action();
      if (mounted) setState(() => _fresh = v);
    } on ApiError catch (e) {
      if (mounted) showGlmToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _left(Duration d) {
    if (d.isNegative) return '0:00';
    final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
    return h > 0 ? '$h:${'$m'.padLeft(2, '0')}:${'$s'.padLeft(2, '0')}' : '$m:${'$s'.padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final repo = ref.read(moneyRepositoryProvider);
    return Scaffold(
      appBar: GameBar(title: Text(l.stadium)),
      body: GlmBackground(
        child: AsyncView(
          value: ref.watch(stadiumProvider(widget.leagueId)),
          onRetry: () => ref.invalidate(stadiumProvider(widget.leagueId)),
          data: (loaded) {
            final s = _fresh ?? loaded;
            final p = context.palette;
            final names = {'seats': l.sectionSeats, 'pitch': l.sectionPitch, 'training': l.sectionTraining};
            final icons = {'seats': Icons.event_seat_rounded, 'pitch': Icons.grass_rounded, 'training': Icons.fitness_center_rounded};
            final b = s.building;
            final left = b == null ? Duration.zero : b.endsAt.difference(DateTime.now().toUtc());
            final finishCoins = b?.finishCoins ?? 0;
            const gap = SizedBox(height: 12);
            final partTime = s.partMinutes >= 120 ? l.hours((s.partMinutes / 60).round()) : l.minutes(s.partMinutes);
            return RefreshIndicator(
              color: p.gold,
              onRefresh: () {
                _fresh = null;
                ref.invalidate(stadiumProvider(widget.leagueId));
                return ref.read(stadiumProvider(widget.leagueId).future);
              },
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  // [Sprint 50 M20] The stadium and its buildings in panorama, in 3D.
                  StadiumPanorama(capacity: '${s.capacity}'),
                  gap,
                  GlmCard(
                    gold: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l.stadiumProgress(s.partsDone, s.partsTotal), textAlign: TextAlign.center, style: context.text.titleMedium),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: s.partsTotal == 0 ? 0 : s.partsDone / s.partsTotal,
                            minHeight: 10,
                            color: p.gold,
                            backgroundColor: p.surfaceRaised,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _Fact(l.capacity, '${s.capacity}')),
                            Expanded(child: _Fact(l.homeAdvantage, '+${(s.homeBp / 100).toStringAsFixed(1)}%')),
                            Expanded(child: _Fact(l.balance, money(context, s.balance))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.partTime(partTime),
                          textAlign: TextAlign.center,
                          style: glmText(GlmType.caption, color: p.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (b != null) ...[
                    gap,
                    GlmCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.construction_rounded, color: p.gold),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l.buildingNow(names[b.section] ?? b.section),
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('${l.stageOf(b.stage)} · ${l.partOf(b.part)}', style: TextStyle(color: p.textMuted)),
                          const SizedBox(height: 6),
                          Text(
                            l.endsIn(_left(left)),
                            style: glmText(
                              GlmType.title,
                              fontFamily: GlmFonts.numbers,
                              fontFamilyFallback: const [GlmFonts.body],
                              fontWeight: FontWeight.w800,
                              color: context.glm.goldText,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GlmButton(
                            label: l.finishNow(finishCoins),
                            variant: GlmButtonVariant.outline,
                            loading: _busy,
                            onPressed: () async {
                              if (await confirm(context, l.finishNowConfirm(finishCoins))) {
                                await _run(() => repo.finishNow(widget.leagueId));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  gap,
                  for (final sec in s.sections)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlmCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(icons[sec.section] ?? Icons.stadium_rounded, color: p.gold),
                                const SizedBox(width: 8),
                                Expanded(child: Text(names[sec.section] ?? sec.section, style: context.text.titleMedium)),
                                Text(
                                  '${sec.stage}/3',
                                  style: glmText(
                                    GlmType.title,
                                    fontFamily: GlmFonts.numbers,
                                    fontWeight: FontWeight.w800,
                                    color: context.glm.goldText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                for (var i = 0; i < 15; i++)
                                  Expanded(
                                    child: Container(
                                      height: 8,
                                      margin: EdgeInsetsDirectional.only(end: i % 5 == 4 ? 6 : 2),
                                      decoration: BoxDecoration(
                                        color: i < sec.done ? p.gold : p.surfaceRaised,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (sec.next == null)
                              Text(
                                l.sectionDone,
                                style: TextStyle(color: context.glm.successText, fontWeight: FontWeight.w800),
                              )
                            else
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${l.stageOf(sec.next!.stage)} · ${l.partOf(sec.next!.part)}',
                                          style: glmText(GlmType.caption, color: p.textMuted),
                                        ),
                                        if (sec.next!.quote case final q?) SpendNote(q),
                                      ],
                                    ),
                                  ),
                                  GlmButton(
                                    label: l.buildPart(money(context, sec.next!.cost)),
                                    loading: _busy && b == null,
                                    onPressed: b != null || _busy ? null : () => _run(() => repo.build(widget.leagueId, sec.section)),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  // [Sprint 50 M21] The store's chests in a row, their odds shown.
                  gap,
                  ChestsRow(leagueId: widget.leagueId),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label, value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        textDirection: TextDirection.ltr,
        style: glmText(GlmType.title, fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: context.palette.text),
      ),
      Text(
        label,
        textAlign: TextAlign.center,
        style: glmText(GlmType.caption, color: context.palette.textMuted),
      ),
    ],
  );
}
