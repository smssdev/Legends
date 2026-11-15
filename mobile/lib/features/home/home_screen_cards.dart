part of 'home_screen.dart';

/// [Sprint 71 N4] A newer app on the site: one tap to the download page (not required; the server's min_version is).
class _UpdateReadyCard extends StatelessWidget {
  const _UpdateReadyCard(this.version);

  final String version;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GlmCard(
        gold: true,
        child: Row(
          children: [
            const IconTile(Icons.system_update_rounded, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: FitLabel(
                l.updateReady(version),
                textAlign: TextAlign.start,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 8),
            GlmButton(
              label: l.updateReadyAction,
              onPressed: () => launchUrl(Uri.parse('${AppConfig.siteUrl}/download'), mode: LaunchMode.externalApplication),
            ),
          ],
        ),
      ),
    );
  }
}

/// The starter gift, once. [Sprint 73 D1] Its words on their own line and the button under them: side by side in the
/// narrow column of a phone 360 high the words ran to four lines of two words each.
class _StarterGiftCard extends ConsumerWidget {
  const _StarterGiftCard(this.coins);

  final int coins;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GlmCard(
        gold: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Pulse(child: IconTile(Icons.redeem_rounded, size: 36)),
                const SizedBox(width: 10),
                Expanded(
                  child: FitLabel(
                    l.starterGift(coins),
                    textAlign: TextAlign.start,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GlmButton(
              block: true,
              label: l.claimGift,
              onPressed: () async {
                try {
                  await ref.read(apiProvider).post('/home/starter-gift');
                  unawaited(GameSounds.play(Sfx.coin));
                } on ApiError catch (e) {
                  if (context.mounted) showGlmToast(context, e.message, error: true);
                }
                ref.invalidate(homeProvider);
              },
            ),
          ],
        ),
      ),
    );
  }
}
