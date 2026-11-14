import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../match/sim_source.dart';
import 'first_match_controller.dart';

/// [Sprint 64 F1] Right after the sign-up: «play your first match». The server makes it (B1) and the live screen plays
/// it with its three moments; on a failure the way on is the home screen, as before.
class FirstMatchScreen extends ConsumerStatefulWidget {
  const FirstMatchScreen({super.key});

  @override
  ConsumerState<FirstMatchScreen> createState() => _FirstMatchScreenState();
}

class _FirstMatchScreenState extends ConsumerState<FirstMatchScreen> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(_start);
  }

  Future<void> _start() async {
    ref.read(firstMatchWantedProvider.notifier).set(false);
    try {
      final handle = await ref.read(introMomentsProvider.notifier).start();
      if (mounted) context.go('/sim/match/${SimMatches.of(handle)!.id}');
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      body: GlmBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlmStateArt(_failed ? 'error' : 'welcome'),
              const SizedBox(height: GlmSpace.md),
              Text(_failed ? l.introFailed : l.introPreparing, style: glmText(GlmType.body)),
              if (_failed) ...[
                const SizedBox(height: GlmSpace.md),
                GlmButton(label: l.introContinue, onPressed: () => context.go('/')),
              ] else
                const Padding(padding: EdgeInsets.all(GlmSpace.md), child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}
