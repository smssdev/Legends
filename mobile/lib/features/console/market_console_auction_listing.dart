part of 'market_console.dart';

/// [Sprint 50 M18] Listing one of my players in an auction: its length, from the server's list.
class AuctionListing extends ConsumerWidget {
  const AuctionListing({super.key, required this.leagueId, required this.playerId, required this.price, required this.onListed});

  final int leagueId, playerId, price;
  final VoidCallback onListed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final minutes = ref.watch(auctionsProvider(leagueId)).value?.minutes ?? const [];
    if (minutes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        GlmSectionTitle(l.listAsAuction),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (final m in minutes)
              ActionChip(
                label: Text(l.auctionMinutes(m)),
                onPressed: () async {
                  try {
                    await ref.read(consoleRepositoryProvider).listAuction(leagueId, playerId, price, m);
                    ref.invalidate(auctionsProvider(leagueId));
                    onListed();
                  } on ApiError catch (e) {
                    if (context.mounted) showGlmToast(context, e.message, error: true);
                  }
                },
              ),
          ],
        ),
      ],
    );
  }
}
