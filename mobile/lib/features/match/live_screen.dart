import '../../ui/art_palette.dart';
import '../../ui/tokens.g.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/api/api_error.dart';
import '../../core/sounds.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/cut.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../../ui/widgets/glm_icon.dart';
import '../../ui/widgets/motion.dart';
import 'feed/art.dart';
import 'feed/broadcast.dart';
import 'feed/story.dart';
import 'live_controller.dart';
import 'live_pitch.dart';
import 'match_data.dart';
import 'orders_controller.dart';
import 'sim_source.dart';
import '../console/console_data.dart';
import '../leagues/shell.dart';

part 'live_state.dart';
part 'live_screen_sheets.dart';
part 'live_screen_social.dart';
part 'live_screen_momentum_strip.dart';
part 'live_screen_event_line.dart';
part 'live_screen_broadcast.dart';

/// [Sprint 17 F2] The live match in the app (the web's /live/{id}): the score bug, the light pitch, the commentary
/// line by line from the server (`text`), and for a coach of either side his orders (a substitution, the tactics or
/// the shape, in the windows) and «أنا مستعد» in a break. It follows the server's minutes (`live?since=`), comes back
/// to now after the phone was locked, and keeps the screen on while it plays.
class LiveMatchScreen extends ConsumerWidget {
  const LiveMatchScreen({super.key, required this.matchId});

  final int matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(matchProvider(matchId));
    if (value.value case final m?) return _Live(view: m);
    return Scaffold(
      appBar: const GameBar(),
      body: GlmBackground(
        child: AsyncView(value: value, onRetry: () => ref.invalidate(matchProvider(matchId)), data: (_) => const SizedBox()),
      ),
    );
  }
}

class _Live extends ConsumerStatefulWidget {
  const _Live({required this.view});

  final MatchView view;

  @override
  ConsumerState<_Live> createState() => _LiveState();
}
