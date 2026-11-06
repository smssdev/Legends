import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import 'leagues_repository.dart';
import 'models.dart';
import 'widgets.dart';

/// [Sprint 16 F1] Take one of the league's clubs with no coach: strongest first, each with its objective. A club taken a
/// moment before by another coach sends the list back (409).
class PickTeamScreen extends ConsumerStatefulWidget {
  const PickTeamScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  ConsumerState<PickTeamScreen> createState() => _PickTeamScreenState();
}

class _PickTeamScreenState extends ConsumerState<PickTeamScreen> {
  ClubCardData? _club;
  bool _busy = false;

  Future<void> _take() async {
    setState(() => _busy = true);
    try {
      await ref.read(leaguesRepositoryProvider).claim(widget.leagueId, _club!.id);
      ref
        ..invalidate(leagueProvider(widget.leagueId))
        ..invalidate(myLeaguesProvider);
      if (mounted) context.pop();
    } on ApiError catch (e) {
      if (!mounted) return;
      showGlmToast(context, e.message, error: true);
      setState(() => _club = null);
      ref.invalidate(leagueClubsProvider(widget.leagueId));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.pickClub)),
      bottomNavigationBar: SafeArea(
        child: Padding(padding: const EdgeInsets.all(16), child: GlmButton(label: l.takeClub, block: true, loading: _busy, onPressed: _club == null ? null : _take)),
      ),
      body: GlmBackground(
        child: AsyncView(
          value: ref.watch(leagueClubsProvider(widget.leagueId)),
          onRetry: () => ref.invalidate(leagueClubsProvider(widget.leagueId)),
          data: (clubs) => ListView(padding: const EdgeInsets.all(16), children: [
            for (final c in clubs.where((c) => c.bot))
              Padding(padding: const EdgeInsets.only(bottom: 8), child: ClubChoice(club: c, selected: _club?.id == c.id, onTap: () => setState(() => _club = c))),
          ]),
        ),
      ),
    );
  }
}
