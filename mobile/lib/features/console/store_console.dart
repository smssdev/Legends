import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/console.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../../ui/widgets/stadium.dart';
import '../club/club_data.dart';
import '../money/finance_screen.dart' show confirm;
import 'console_data.dart';

/// [Sprint 50 M20] The stadium in panorama: the 3D stadium of ours with its buildings (the academy, the medical centre,
/// the offices), turned by the finger, their names over it. The drawn stadium stands in where 3D cannot turn.
class StadiumPanorama extends StatelessWidget {
  const StadiumPanorama({super.key, required this.capacity});

  final String capacity;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    Widget tag(String text, Color edge) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: p.bgDeep.withValues(alpha: .85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: edge),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: SizedBox(
        height: 190,
        child: Stack(
          children: [
            Positioned.fill(
              child: GlmModel3D(
                model: 'stadium',
                label: l.stadium,
                orbit: '30deg 62deg 6m',
                fallback: const StadiumBackdrop(child: SizedBox.expand()),
              ),
            ),
            PositionedDirectional(top: 8, start: 8, child: tag(l.academy, p.brandLight)),
            PositionedDirectional(top: 8, end: 8, child: tag(l.medical, p.danger)),
            PositionedDirectional(bottom: 8, end: 8, child: tag(l.offices, p.gold)),
            PositionedDirectional(bottom: 8, start: 8, child: tag('${l.capacity}: $capacity', p.gold)),
          ],
        ),
      ),
    );
  }
}

/// [Sprint 50 M21] The store's chests in a row: each its 3D chest, its coins, and its odds shown before it is opened
/// (the server's table); opening one says what it gave.
class ChestsRow extends ConsumerWidget {
  const ChestsRow({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final chests = ref.watch(chestsProvider(leagueId)).value;
    if (chests == null || chests.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlmSectionTitle(l.chests),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final c in chests)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _ChestCard(leagueId: leagueId, chest: c),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

String _rewardText(L l, String reward, int amount) => switch (reward) {
  'coins' => l.rewardCoins(amount),
  'fitness' => l.rewardFitness(amount),
  'training' => l.rewardTraining,
  _ => l.rewardMorale(amount),
};

class _ChestCard extends ConsumerStatefulWidget {
  const _ChestCard({required this.leagueId, required this.chest});

  final int leagueId;
  final Chest chest;

  @override
  ConsumerState<_ChestCard> createState() => _ChestCardState();
}

class _ChestCardState extends ConsumerState<_ChestCard> {
  bool _busy = false;

  Future<void> _open() async {
    final l = L.of(context);
    final c = widget.chest;
    if (!await confirm(context, '${_name(l, c.chest)} · ${l.openFor(c.coins)}')) return;
    setState(() => _busy = true);
    try {
      final got = await ref.read(consoleRepositoryProvider).openChest(widget.leagueId, c.chest);
      unawaited(HapticFeedback.heavyImpact());
      ref.invalidate(clubSummaryProvider(widget.leagueId));
      if (!mounted) return;
      setState(() => _busy = false);
      await showDialog<void>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text(l.youGot, textAlign: TextAlign.center),
          content: Text(
            _rewardText(l, got.reward, got.amount),
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: d.palette.goldLight),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(d), child: Text(l.confirm))],
        ),
      );
    } on ApiError catch (e) {
      if (mounted) showGlmToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _name(L l, String chest) => switch (chest) {
    'bronze' => l.chestBronze,
    'silver' => l.chestSilver,
    _ => l.chestLegend,
  };

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final c = widget.chest;
    final legend = c.chest == 'legend';
    final colour = switch (c.chest) {
      'bronze' => p.bronze,
      'silver' => p.silver,
      _ => p.gold,
    };
    return GlmCard(
      gold: legend,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 92,
            child: GlmModel3D(
              model: 'chest_${c.chest}',
              label: _name(l, c.chest),
              fallback: Icon(Icons.inventory_2_rounded, size: 64, color: colour),
            ),
          ),
          Text(
            _name(l, c.chest),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w800, color: legend ? p.goldLight : p.text),
          ),
          const SizedBox(height: 4),
          // The odds, before it is opened.
          for (final o in c.odds)
            Row(
              children: [
                Expanded(
                  child: Text(
                    _rewardText(l, o.reward, o.amount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.textMuted, fontSize: 10),
                  ),
                ),
                Text(
                  '${(o.pctBp / 100).toStringAsFixed(o.pctBp % 100 == 0 ? 0 : 1)}%',
                  style: TextStyle(color: p.textSoft, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          const SizedBox(height: 6),
          GlmButton(
            label: l.openFor(c.coins),
            variant: legend ? GlmButtonVariant.primary : GlmButtonVariant.quiet,
            block: true,
            loading: _busy,
            onPressed: _open,
          ),
        ],
      ),
    );
  }
}
