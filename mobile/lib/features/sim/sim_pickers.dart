import '../../ui/tokens.g.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/brand.dart';
import 'sim_repository.dart';

/// A club to pick: its crest, its name, its strength; the chosen one framed in gold.
class TeamChip extends StatelessWidget {
  const TeamChip({super.key, required this.club, required this.on, required this.onTap});

  final SimClub club;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: on ? p.gold.withValues(alpha: .12) : p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: on ? p.gold : p.surfaceRaised, width: 2),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
        child: SizedBox(
          width: 86,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClubCrest(url: club.logo, name: club.code, size: 36, color: club.color),
                const SizedBox(height: 4),
                Text(
                  club.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: glmText(GlmType.caption, fontWeight: FontWeight.w700),
                ),
                if (club.strength != null)
                  Text(
                    '${club.strength}',
                    style: glmText(
                      GlmType.body,
                      fontFamily: GlmFonts.numbers,
                      fontWeight: FontWeight.w700,
                      color: on ? context.glm.goldText : p.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The opponent: the one picked, or a random one from the strongest.
class OpponentRow extends StatelessWidget {
  const OpponentRow({super.key, required this.club, required this.onTap, this.onClear});

  final SimClub? club;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: p.surfaceRaised),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (club == null)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: p.gold, width: 2),
                  ),
                  child: Icon(Icons.shuffle_rounded, color: p.gold, size: 20),
                )
              else
                ClubCrest(url: club!.logo, name: club!.code, size: 36, color: club!.color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  club?.name ?? l.simRandom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: club == null ? null : TextDirection.ltr,
                  style: glmText(GlmType.body, fontWeight: FontWeight.w700),
                ),
              ),
              if (club?.strength != null) Text(l.simStrength(club!.strength!), style: glmText(GlmType.caption, color: p.textMuted)),
              if (onClear != null)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The search for any club, in a sheet.
class ClubSearch extends ConsumerStatefulWidget {
  const ClubSearch({super.key});

  @override
  ConsumerState<ClubSearch> createState() => _ClubSearchState();
}

class _ClubSearchState extends ConsumerState<ClubSearch> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final found = ref.watch(simClubsProvider(_q));
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: true,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(hintText: l.simSearch, prefixIcon: const Icon(Icons.search_rounded)),
                onChanged: (v) => setState(() => _q = v),
              ),
            ),
            Expanded(
              child: found.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(e is ApiError && e.status == 404 ? l.simOff : '$e', style: TextStyle(color: p.textMuted)),
                ),
                data: (clubs) => ListView(
                  children: [
                    for (final c in clubs)
                      ListTile(
                        leading: ClubCrest(url: c.logo, name: c.code, size: 36, color: c.color),
                        title: Text(c.name, textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                        subtitle: c.league == null
                            ? null
                            : Text(
                                c.league!,
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.start,
                                style: glmText(GlmType.caption, color: p.textMuted),
                              ),
                        trailing: c.strength == null
                            ? null
                            : Text(
                                '${c.strength}',
                                style: glmText(GlmType.title, fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700),
                              ),
                        onTap: () => Navigator.pop(context, c),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
