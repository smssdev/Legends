import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';
import '../../core/sounds.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/game.dart';
import '../../ui/widgets/glm_card.dart';
import '../../ui/widgets/motion.dart';
import '../../ui/widgets/stadium.dart';
import '../home/home_data.dart';
import '../leagues/widgets.dart' show when;
import '../leagues/shell.dart';

/// [Sprint 18 F1] The coins wallet (Sprint 34) and the store (Sprint 43 W2): the balance, today's coins, the latest
/// movements, and the packages and timed offers, each ordered on WhatsApp as on the site (no payment in the app).
class WalletView {
  const WalletView({required this.balance, required this.daily, required this.dailyClaimed, required this.transactions});

  factory WalletView.fromJson(Map<String, dynamic> j) => WalletView(
        balance: (j['balance'] as num?)?.toInt() ?? 0,
        daily: ((j['daily'] as Map<dynamic, dynamic>?)?['amount'] as num?)?.toInt() ?? 0, dailyClaimed: (j['daily'] as Map<dynamic, dynamic>?)?['claimed'] == true,
        transactions: [
          for (final t in (j['transactions'] as List<dynamic>? ?? const []))
            (label: '${(t as Map<dynamic, dynamic>)['label']}', amount: (t['amount'] as num).toInt(), at: DateTime.tryParse('${t['at'] ?? ''}')),
        ],
      );

  final int balance, daily;
  final bool dailyClaimed;
  final List<({String label, int amount, DateTime? at})> transactions;
}

class StoreItem {
  const StoreItem({required this.title, required this.description, required this.price, this.oldPrice, required this.currency, this.discount,
      this.endsAt, this.imageUrl, this.whatsappUrl, required this.offer});

  factory StoreItem.fromJson(Map<String, dynamic> j) => StoreItem(
        title: '${j['title']}', description: '${j['description'] ?? ''}', price: (j['price'] as num?)?.toInt() ?? 0, oldPrice: (j['old_price'] as num?)?.toInt(),
        currency: '${j['currency'] ?? ''}', discount: j['discount'] as int?, endsAt: DateTime.tryParse('${j['ends_at'] ?? ''}'),
        imageUrl: j['image_url'] as String?, whatsappUrl: j['whatsapp_url'] as String?, offer: j['kind'] == 'offer',
      );

  final String title, description, currency;
  final int price;
  final int? oldPrice, discount;
  final DateTime? endsAt;
  final String? imageUrl, whatsappUrl;
  final bool offer;
}

class WalletRepository {
  WalletRepository(this._api);

  final ApiClient _api;

  Future<WalletView> wallet() async => WalletView.fromJson(await _api.get('/wallet'));
  Future<void> claimDaily() => _api.post('/wallet/daily');
  Future<List<StoreItem>> store() async => [
        for (final i in ((await _api.get('/store'))['items'] as List<dynamic>? ?? const []))
          if ((i as Map<dynamic, dynamic>)['ended'] != true && i['visible'] != false) StoreItem.fromJson(i as Map<String, dynamic>),
      ];
}

final walletRepositoryProvider = Provider<WalletRepository>((ref) => WalletRepository(ref.watch(apiProvider)));
final walletProvider = FutureProvider.autoDispose<WalletView>((ref) => ref.read(walletRepositoryProvider).wallet());
final storeProvider = FutureProvider.autoDispose<List<StoreItem>>((ref) => ref.read(walletRepositoryProvider).store());

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = context.palette;
    return Scaffold(
      appBar: GameBar(title: Text(l.wallet)),
      body: GlmBackground(
        wide: true,
        child: AsyncView(
          value: ref.watch(walletProvider),
          onRetry: () => ref.invalidate(walletProvider),
          data: (w) => RefreshIndicator(
            color: p.gold,
            onRefresh: () {
              ref.invalidate(storeProvider);
              return ref.refresh(walletProvider.future);
            },
            // [2026-11-06, stage 3] In landscape: the balance and its movements on one side, the store on the other.
            child: GamePanes(startFlex: 1, endFlex: 1, start: [
              GlmCard(
                gold: true,
                accent: p.gold,
                child: Column(children: [
                  Text(l.coins, style: TextStyle(color: p.textMuted)),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Image.asset('assets/brand/coin.png', width: 40, height: 40),
                    const SizedBox(width: 10),
                    CountUp(w.balance, style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 48, fontWeight: FontWeight.w800, color: context.glm.goldText, height: 1)),
                  ]),
                  const SizedBox(height: 8),
                  GlmButton(
                    label: w.dailyClaimed ? l.dailyClaimed : l.claimDaily,
                    icon: const Icon(Icons.card_giftcard_rounded),
                    onPressed: w.dailyClaimed
                        ? null
                        : () async {
                            try {
                              await ref.read(walletRepositoryProvider).claimDaily();
                              GameSounds.play(Sfx.coin);
                            } on ApiError catch (e) {
                              if (context.mounted) showGlmToast(context, e.message, error: true);
                            }
                            ref.invalidate(walletProvider);
                            ref.invalidate(homeProvider);
                          },
                  ),
                  if (!w.dailyClaimed) Padding(padding: const EdgeInsets.only(top: 4), child: Text(l.dailyCoins(w.daily), style: TextStyle(color: p.textMuted, fontSize: 12))),
                ]),
              ),
              if (w.transactions.isNotEmpty) ...[
                SectionTitle(l.transactions),
                GlmCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Column(children: [
                    for (final t in w.transactions)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: IconTile(t.amount >= 0 ? Icons.add_rounded : Icons.remove_rounded, size: 32, color: t.amount >= 0 ? p.success : p.live),
                        title: Text(t.label),
                        subtitle: t.at == null ? null : Text(when(context, t.at!.toLocal())),
                        trailing: Text('${t.amount > 0 ? '+' : ''}${t.amount}', textDirection: TextDirection.ltr,
                            style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 17, color: t.amount >= 0 ? context.glm.successText : context.glm.liveText)),
                      ),
                  ]),
                ),
              ],
            ], end: [
              SectionTitle(l.store),
              ...?ref.watch(storeProvider).value?.map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlmCard(
                      gold: i.offer,
                      padding: EdgeInsets.zero,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        if (i.imageUrl != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(GlmCard.radius)),
                            child: AspectRatio(
                              aspectRatio: isWide(context) ? 2.4 : 16 / 9,
                              // Until the picture arrives, or when it cannot: the night stadium with the coin.
                              child: Image.network(i.imageUrl!, fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => StadiumBackdrop(pitch: false, child: Center(child: Image.asset('assets/brand/coin.png', width: 56, height: 56)))),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            Text(i.title, style: context.text.titleMedium),
                            if (i.description.isNotEmpty) Text(i.description, style: TextStyle(color: p.textMuted)),
                            const SizedBox(height: 8),
                            Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                              Text('${i.price} ${i.currency}', style: TextStyle(fontFamily: GlmFonts.numbers, fontFamilyFallback: const [GlmFonts.body], fontSize: 22, fontWeight: FontWeight.w800, color: context.glm.goldText)),
                              if (i.oldPrice != null) Text('${i.oldPrice}', style: TextStyle(color: p.textMuted, decoration: TextDecoration.lineThrough)),
                            ]),
                            if (i.endsAt != null && i.offer) Text(l.endsOn(when(context, i.endsAt!.toLocal())), style: TextStyle(color: context.glm.liveText, fontSize: 12)),
                            if (i.whatsappUrl != null) ...[
                              const SizedBox(height: 10),
                              GlmButton(
                                label: l.buyOnWhatsapp,
                                variant: GlmButtonVariant.brand,
                                block: true,
                                onPressed: () => launchUrl(Uri.parse(i.whatsappUrl!), mode: LaunchMode.externalApplication),
                              ),
                            ],
                          ]),
                        ),
                      ]),
                    ),
                  )),
            ]),
          ),
        ),
      ),
    );
  }
}
