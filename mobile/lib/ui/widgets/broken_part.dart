import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme.dart';
import '../tokens.g.dart';

/// [Sprint 66 F1] What the player sees in place of a part that failed to build (Flutter's red box in development, a
/// grey one in a release): a calm card in the night's colours and one line. The error itself is sent
/// (core/crash_reports.dart).
class BrokenPart extends StatelessWidget {
  const BrokenPart({super.key});

  @override
  Widget build(BuildContext context) {
    final l = Localizations.of<L>(context, L);
    return ColoredBox(
      color: glmNight.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.build_circle_rounded, color: glmNight.textMuted, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l?.brokenPart ?? '…',
                  textAlign: TextAlign.center,
                  style: glmText(GlmType.body, color: glmNight.textSoft).copyWith(decoration: TextDecoration.none),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
