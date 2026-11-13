import '../../ui/tokens.g.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../core/config.dart';
import '../../core/sounds.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../leagues/shell.dart' show GameBar;
import 'sim_face_off.dart';
import 'sim_pickers.dart';
import 'sim_repository.dart';
import 'sim_versus_screen.dart';

/// [Sprint 47] The simulator in the app, as in the approved design: a trial match apart from the leagues, against the
/// computer or a friend. The two crests face each other over the night pitch with a VS between them; the two modes as
/// cards; your team and the opponent picked from the data's clubs; the gold button. The match itself is played on the
/// simulator's page (the site's, the same for both friends), opened after the face-off.
class SimSetupScreen extends ConsumerStatefulWidget {
  const SimSetupScreen({super.key});

  @override
  ConsumerState<SimSetupScreen> createState() => _SimSetupScreenState();
}

class _SimSetupScreenState extends ConsumerState<SimSetupScreen> {
  bool _friend = false;
  SimClub? _me, _them;
  bool _busy = false;

  Future<void> _start(List<SimClub> clubs) async {
    final l = L.of(context);
    final me = _me ?? (clubs.isNotEmpty ? clubs.first : null);
    if (me == null) return;
    final rest = clubs.where((c) => c.id != me.id).toList();
    final them = _them != null && _them!.id != me.id
        ? _them!
        : (rest.isEmpty ? null : rest[math.Random().nextInt(math.min(rest.length, 12))]);
    if (them == null) return;
    setState(() => _busy = true);
    try {
      final m = await ref.read(simRepositoryProvider).create(me: me, them: them, friend: _friend);
      if (!mounted) return;
      unawaited(GameSounds.play(Sfx.whistle));
      await Navigator.of(context).push(
        PageRouteBuilder<void>(
          pageBuilder: (_, _, _) => SimVersusScreen(
            home: me,
            away: them,
            friend: _friend,
            matchUrl: '${AppConfig.siteUrl}/sim/${m.id}${m.home == null ? '' : '?seat=${m.home}'}',
            inviteUrl: m.away == null ? null : '${AppConfig.siteUrl}/sim/${m.id}?seat=${m.away}',
          ),
          transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
        ),
      );
    } on ApiError catch (e) {
      if (mounted) showGlmToast(context, e.status == 404 ? l.simOff : e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick(bool mine) async {
    final picked = await showModalBottomSheet<SimClub>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const ClubSearch(),
    );
    if (picked != null && mounted) setState(() => mine ? _me = picked : _them = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final clubs = ref.watch(simClubsProvider(''));
    final list = clubs.value ?? const <SimClub>[];
    final me = _me ?? (list.isNotEmpty ? list.first : null);
    return Scaffold(
      appBar: GameBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.simTitle, style: glmText(GlmType.title, fontWeight: FontWeight.w800)),
            Text(
              l.simLead,
              style: glmText(GlmType.caption, color: p.textMuted, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsetsDirectional.only(end: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: p.success.withValues(alpha: .16), borderRadius: BorderRadius.circular(14)),
            child: Text(
              l.simFree,
              style: glmText(GlmType.caption, color: context.glm.successText, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: GlmBackground(
        wide: true,
        child: LayoutBuilder(
          builder: (context, box) {
            final modes = Row(
              children: [
                Expanded(
                  child: _ModeCard(
                    on: !_friend,
                    icon: Icons.smart_toy_rounded,
                    iconColor: p.ring,
                    title: l.simVsCpu,
                    lead: l.simVsCpuLead,
                    onTap: () => setState(() => _friend = false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeCard(
                    on: _friend,
                    icon: Icons.group_rounded,
                    iconColor: p.gold,
                    title: l.simVsFriend,
                    lead: l.simVsFriendLead,
                    onTap: () => setState(() => _friend = true),
                  ),
                ),
              ],
            );
            final teams = SizedBox(
              height: 96,
              child: clubs.isLoading && list.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : clubs.hasError && list.isEmpty
                  ? Center(
                      child: Text(
                        clubs.error is ApiError && (clubs.error as ApiError).status == 404 ? l.simOff : '${clubs.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: p.textMuted),
                      ),
                    )
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final c in [if (_me != null && !list.take(10).any((x) => x.id == _me!.id)) _me!, ...list.take(10)])
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: TeamChip(club: c, on: c.id == me?.id, onTap: () => setState(() => _me = c)),
                          ),
                      ],
                    ),
            );
            final picks = <Widget>[
              _Label(l.simYourTeam, action: l.simSearch, onAction: () => _pick(true)),
              const SizedBox(height: 6),
              teams,
              const SizedBox(height: 10),
              _Label(l.simOpponent, action: l.simSearch, onAction: () => _pick(false)),
              const SizedBox(height: 6),
              OpponentRow(club: _them, onTap: () => _pick(false), onClear: _them == null ? null : () => setState(() => _them = null)),
            ];
            final go = GlmButton(
              label: _friend ? l.simOpenRoom : l.simStart,
              block: true,
              loading: _busy,
              icon: const Icon(Icons.play_arrow_rounded),
              onPressed: list.isEmpty ? null : () => _start(list),
            );
            // [Sprint 47] The phone is held sideways (the app is landscape): the face-off and the two modes on one side,
            // the teams and the gold button on the other, all in sight at once.
            if (box.maxWidth > box.maxHeight) {
              return SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 11,
                        child: Column(
                          children: [
                            Expanded(
                              child: FaceOff(home: me, away: _them, friend: _friend),
                            ),
                            const SizedBox(height: 10),
                            modes,
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 9,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: picks),
                              ),
                            ),
                            const SizedBox(height: 10),
                            go,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
              children: [
                SizedBox(
                  height: 190,
                  child: FaceOff(home: me, away: _them, friend: _friend),
                ),
                const SizedBox(height: 12),
                modes,
                const SizedBox(height: 16),
                ...picks,
                const SizedBox(height: 22),
                go,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.action, this.onAction});

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          text,
          style: glmText(GlmType.body, fontWeight: FontWeight.w800, color: context.palette.textSoft),
        ),
      ),
      if (action != null)
        TextButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.search_rounded, size: 18),
          label: Text(action!),
          style: TextButton.styleFrom(
            foregroundColor: context.glm.brandText,
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontFamily: GlmFonts.body),
          ),
        ),
    ],
  );
}

/// A mode: its icon, its name and its line, the chosen one in a mint ring.
class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.on,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.lead,
    required this.onTap,
  });

  final bool on;
  final IconData icon;
  final Color iconColor;
  final String title, lead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ring = context.glm.day ? p.brand : p.ring;
    return Semantics(
      selected: on,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: on ? p.brand.withValues(alpha: .16) : p.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: on ? ring : p.surfaceRaised, width: 2),
          boxShadow: on ? [BoxShadow(color: ring.withValues(alpha: .15), spreadRadius: 4)] : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () {
              GameSounds.play(Sfx.tap);
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: glmText(GlmType.bodyLg, fontWeight: FontWeight.w800)),
                        Text(
                          lead,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: glmText(GlmType.caption, color: p.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
