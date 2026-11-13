import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';
import '../../core/api/response_cache.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';

/// [Sprint 61 F9] One bar at the top of the frame while the server cannot be reached: the screens keep what they
/// last showed (their saved answers) under it. While it shows, the server is asked every few seconds; at its first
/// answer the bar goes and the screens ask again (reconnectedProvider).
class OfflineBar extends ConsumerStatefulWidget {
  const OfflineBar({super.key, required this.child});

  final Widget child;

  static const probeEvery = Duration(seconds: 5);

  @override
  ConsumerState<OfflineBar> createState() => _OfflineBarState();
}

class _OfflineBarState extends ConsumerState<OfflineBar> {
  Timer? _probe;

  @override
  void dispose() {
    _probe?.cancel();
    super.dispose();
  }

  void _watch(bool online) {
    _probe?.cancel();
    _probe = online
        ? null
        : Timer.periodic(OfflineBar.probeEvery, (_) async {
            try {
              // One try a tick (the client's own retries would only stack up behind the next tick).
              await ref.read(apiProvider).dio.get<dynamic>('/health');
              ref.read(onlineProvider.notifier).set(true);
            } catch (e) {
              if (ApiError.from(e).status != null) ref.read(onlineProvider.notifier).set(true);
            }
          });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(onlineProvider, (_, online) => _watch(online));
    final online = ref.watch(onlineProvider);
    final p = context.palette;
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: online
              ? const SizedBox(width: double.infinity)
              : Material(
                  color: p.warning,
                  child: SafeArea(
                    bottom: false,
                    child: Semantics(
                      liveRegion: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: GlmSpace.md, vertical: GlmSpace.xs),
                        child: Row(
                          children: [
                            Icon(Icons.wifi_off_rounded, size: 18, color: p.onGold),
                            const SizedBox(width: GlmSpace.sm),
                            Expanded(
                              child: Text(
                                L.of(context).offlineBar,
                                style: context.type.caption.copyWith(color: p.onGold, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
        Expanded(
          child: MediaQuery.removePadding(context: context, removeTop: !online, child: widget.child),
        ),
      ],
    );
  }
}
