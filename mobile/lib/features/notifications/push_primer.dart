import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import 'push.dart';

/// [Sprint 64 F12, M-S07] Before the system asks for notifications: a card that says what they bring (your lineup an
/// hour before, your match half an hour before, an offer), after the first match. «Allow» then the system's own
/// question; «later» hides it for a week. Never shown again once allowed.
class PushPrimer extends ConsumerStatefulWidget {
  const PushPrimer({super.key, required this.played});

  /// The coach has played a match (the primer waits for his first).
  final bool played;

  @override
  ConsumerState<PushPrimer> createState() => _PushPrimerState();
}

class _PushPrimerState extends ConsumerState<PushPrimer> {
  bool _gone = false;

  bool _due() {
    final prefs = ref.read(preferencesProvider);
    if (!widget.played || _gone || (prefs.getBool(pushPrimedKey) ?? false)) return false;
    final later = prefs.getInt(pushLaterKey);
    return later == null || DateTime.now().millisecondsSinceEpoch - later > const Duration(days: 7).inMilliseconds;
  }

  @override
  Widget build(BuildContext context) {
    if (!_due()) return const SizedBox.shrink();
    final l = L.of(context);
    final prefs = ref.read(preferencesProvider);
    return GlmCard(
      gold: true,
      child: Row(
        children: [
          const GlmStateArt('welcome', size: 48),
          const SizedBox(width: GlmSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.pushPrimerTitle, style: glmText(GlmType.title, color: context.glm.goldText)),
                Text(l.pushPrimerBody, style: glmText(GlmType.body)),
                const SizedBox(height: GlmSpace.sm),
                Wrap(
                  spacing: GlmSpace.sm,
                  children: [
                    GlmButton(
                      label: l.pushPrimerAllow,
                      onPressed: () async {
                        await prefs.setBool(pushPrimedKey, true);
                        setState(() => _gone = true);
                        unawaited(ref.read(pushProvider).start());
                      },
                    ),
                    GlmButton(
                      label: l.pushPrimerLater,
                      variant: GlmButtonVariant.quiet,
                      onPressed: () async {
                        await prefs.setInt(pushLaterKey, DateTime.now().millisecondsSinceEpoch);
                        setState(() => _gone = true);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
