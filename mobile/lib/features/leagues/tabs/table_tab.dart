import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/theme.dart';
import '../../../ui/tokens.g.dart';
import '../../../ui/widgets/async_view.dart';
import '../../../ui/widgets/brand.dart';
import '../leagues_repository.dart';
import '../models.dart';

class TableTab extends ConsumerWidget {
  const TableTab(this.lg, {super.key});

  final League lg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    TextStyle num([bool strong = false]) => TextStyle(
      fontFamily: GlmFonts.numbers,
      fontSize: 16,
      fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
      color: strong ? p.text : p.textSoft,
    );
    return RefreshIndicator(
      onRefresh: () => ref.refresh(standingsProvider(lg.id).future),
      child: AsyncView(
        value: ref.watch(standingsProvider(lg.id)),
        onRetry: () => ref.invalidate(standingsProvider(lg.id)),
        data: (rows) => ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final r in rows)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: r.id == lg.myClubId ? p.gold.withValues(alpha: .14) : p.surface,
                  borderRadius: BorderRadius.circular(GlmSize.radiusLg),
                  border: Border.all(color: r.id == lg.myClubId ? p.gold.withValues(alpha: .5) : p.surfaceRaised),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 26, child: Text('${r.position}', style: num(true))),
                    ClubCrest(url: r.crestUrl, name: r.code, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (r.coach != null)
                            Text(
                              r.coach!,
                              style: TextStyle(color: p.textMuted, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 28,
                      child: Text('${r.played}', style: num(), textAlign: TextAlign.center),
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${r.gd > 0 ? '+' : ''}${r.gd}',
                        style: num(),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                    SizedBox(
                      width: 34,
                      child: Text('${r.points}', style: num(true), textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
