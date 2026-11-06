import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_text_field.dart';
import 'leagues_repository.dart';
import 'models.dart';
import 'widgets.dart';

final _templatesProvider = FutureProvider.autoDispose((ref) => ref.read(leaguesRepositoryProvider).templates());
final _templateClubsProvider = FutureProvider.autoDispose.family<List<ClubCardData>, String>((ref, t) => ref.read(leaguesRepositoryProvider).templateClubs(t));

/// [Sprint 16 F1] The free league from the app (UP9): the league to copy, my team in it, a name if I want one. It starts
/// tomorrow at 9 pm with two days to get ready, as the web's default; the paid options stay on the site.
class CreateLeagueScreen extends ConsumerStatefulWidget {
  const CreateLeagueScreen({super.key});

  @override
  ConsumerState<CreateLeagueScreen> createState() => _CreateLeagueScreenState();
}

class _CreateLeagueScreenState extends ConsumerState<CreateLeagueScreen> {
  String? _template;
  ClubCardData? _club;
  final _name = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_template == null || _club == null) return;
    setState(() => _busy = true);
    final now = DateTime.now();
    try {
      final league = await ref.read(leaguesRepositoryProvider).create(template: _template!, masterClubId: _club!.id, name: _name.text,
          startsAt: DateTime(now.year, now.month, now.day + 1, 21));
      ref.invalidate(myLeaguesProvider);
      if (mounted) context.pushReplacement('/leagues/${league.id}');
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
    return Scaffold(
      appBar: AppBar(title: Text(l.newLeague)),
      bottomNavigationBar: SafeArea(
        child: Padding(padding: const EdgeInsets.all(16), child: GlmButton(label: l.create, block: true, loading: _busy, onPressed: _template != null && _club != null ? _create : null)),
      ),
      body: GlmBackground(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text(l.freeLeagueLead, style: TextStyle(color: p.textSoft, height: 1.6)),
          SectionTitle(l.pickTemplate),
          AsyncView(
            value: ref.watch(_templatesProvider),
            onRetry: () => ref.invalidate(_templatesProvider),
            data: (templates) => Wrap(spacing: 8, runSpacing: 8, children: [
              for (final t in templates)
                ChoiceChip(
                  label: Text('${t.name} · ${t.clubs}'),
                  selected: _template == t.name,
                  selectedColor: p.gold.withValues(alpha: .25),
                  onSelected: (_) => setState(() {
                    _template = t.name;
                    _club = null;
                  }),
                ),
            ]),
          ),
          if (_template != null) ...[
            SectionTitle(l.pickClub),
            AsyncView(
              value: ref.watch(_templateClubsProvider(_template!)),
              data: (clubs) => Column(children: [
                for (final c in clubs)
                  Padding(padding: const EdgeInsets.only(bottom: 8), child: ClubChoice(club: c, selected: _club?.id == c.id, onTap: () => setState(() => _club = c))),
              ]),
            ),
            const SizedBox(height: 8),
            GlmTextField(label: l.leagueName, controller: _name, action: TextInputAction.done),
          ],
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}
