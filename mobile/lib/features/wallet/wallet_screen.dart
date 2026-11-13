import '../../ui/tokens.g.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/gen/models.g.dart' as api;
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

  /// [Sprint 59 F1] From the generated model (`WalletView` in openapi.yaml).
  factory WalletView.fromJson(Object? json) => WalletView.of(api.WalletView.fromJson(json));

  factory WalletView.of(api.WalletView w) => WalletView(
    balance: w.balance,
    daily: w.daily.amount,
    dailyClaimed: w.daily.claimed,
    transactions: [for (final t in w.transactions) (label: t.label, amount: t.amount, at: DateTime.tryParse(t.at))],
  );

  final int balance, daily;
  final bool dailyClaimed;
  final List<({String label, int amount, DateTime? at})> transactions;
}

class StoreItem {
  const StoreItem({
    required this.title,
    required this.description,
    required this.price,
    this.oldPrice,
    required this.currency,
    this.discount,
    this.endsAt,
    this.imageUrl,
    this.whatsappUrl,
    required this.offer,
  });

  /// [Sprint 59 F1] From the generated model (an item of `GET /store`, `StoreAnswer`).
  factory StoreItem.of(api.StoreAnswerItemsItem i) => StoreItem(
    title: i.title,
    description: i.description,
    price: i.price,
    oldPrice: i.oldPrice,
    currency: i.currency,
    discount: i.discount,
    endsAt: i.endsAt == null ? null : DateTime.tryParse(i.endsAt!),
    imageUrl: i.imageUrl,
    whatsappUrl: i.whatsappUrl,
    offer: i.kind == 'offer',
  );

  /// What the store shows of `GET /store`: the items still on (an ended offer or a hidden item never).
  static List<StoreItem> shown(Object? json) => [
    for (final i in api.StoreAnswer.fromJson(json).items)
      if (!i.ended && i.visible) StoreItem.of(i),
  ];

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
  Future<List<StoreItem>> store() async => StoreItem.shown(await _api.get('/store'));
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
            child: GamePanes(
              startFlex: 1,
              endFlex: 1,
              start: [
                GlmCard(
                  gold: true,
                  accent: p.gold,
                  child: Column(
                    children: [
                      Text(l.coins, style: TextStyle(color: p.textMuted)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/brand/coin.png', width: 40, height: 40),
                          const SizedBox(width: 10),
                          CountUp(
                            w.balance,
                            style: glmText(
                              GlmType.displayLg,
                              fontFamily: GlmFonts.numbers,
                              fontWeight: FontWeight.w800,
                              color: context.glm.goldText,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GlmButton(
                        label: w.dailyClaimed ? l.dailyClaimed : l.claimDaily,
                        icon: const Icon(Icons.card_giftcard_rounded),
                        onPressed: w.dailyClaimed
                            ? null
                            : () async {
                                try {
                                  await ref.read(walletRepositoryProvider).claimDaily();
                                  unawaited(GameSounds.play(Sfx.coin));
                                } on ApiError catch (e) {
                                  if (context.mounted) showGlmToast(context, e.message, error: true);
                                }
                                ref.invalidate(walletProvider);
                                ref.invalidate(homeProvider);
                              },
                      ),
                      if (!w.dailyClaimed)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(l.dailyCoins(w.daily), style: glmText(GlmType.caption, color: p.textMuted)),
                        ),
                    ],
                  ),
                ),
                if (w.transactions.isNotEmpty) ...[
                  SectionTitle(l.transactions),
                  GlmCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Column(
                      children: [
                        for (final t in w.transactions)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: IconTile(
                              t.amount >= 0 ? Icons.add_rounded : Icons.remove_rounded,
                              size: 32,
                              color: t.amount >= 0 ? p.success : p.live,
                            ),
                            title: Text(t.label),
                            subtitle: t.at == null ? null : Text(when(context, t.at!.toLocal())),
                            trailing: Text(
                              '${t.amount > 0 ? '+' : ''}${t.amount}',
                              textDirection: TextDirection.ltr,
                              style: glmText(
                                GlmType.bodyLg,
                                fontFamily: GlmFonts.numbers,
                                fontWeight: FontWeight.w800,
                                color: t.amount >= 0 ? context.glm.successText : context.glm.liveText,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
              end: [
                SectionTitle(l.store),
                ...?ref
                    .watch(storeProvider)
                    .value
                    ?.map(
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlmCard(
                          gold: i.offer,
                          padding: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (i.imageUrl != null)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(GlmCard.radius)),
                                  child: AspectRatio(
                                    aspectRatio: isWide(context) ? 2.4 : 16 / 9,
                                    // Until the picture arrives, or when it cannot: the night stadium with the coin.
                                    child: Image.network(
                                      i.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => StadiumBackdrop(
                                        pitch: false,
                                        child: Center(child: Image.asset('assets/brand/coin.png', width: 56, height: 56)),
                                      ),
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(i.title, style: context.text.titleMedium),
                                    if (i.description.isNotEmpty) Text(i.description, style: TextStyle(color: p.textMuted)),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          '${i.price} ${i.currency}',
                                          style: glmText(
                                            GlmType.headline,
                                            fontFamily: GlmFonts.numbers,
                                            fontFamilyFallback: const [GlmFonts.body],
                                            fontWeight: FontWeight.w800,
                                            color: context.glm.goldText,
                                          ),
                                        ),
                                        if (i.oldPrice != null)
                                          Text(
                                            '${i.oldPrice}',
                                            style: TextStyle(color: p.textMuted, decoration: TextDecoration.lineThrough),
                                          ),
                                      ],
                                    ),
                                    if (i.endsAt != null && i.offer)
                                      Text(
                                        l.endsOn(when(context, i.endsAt!.toLocal())),
                                        style: glmText(GlmType.caption, color: context.glm.liveText),
                                      ),
                                    if (i.whatsappUrl != null) ...[
                                      const SizedBox(height: 10),
                                      GlmButton(
                                        label: l.buyOnWhatsapp,
                                        variant: GlmButtonVariant.brand,
                                        block: true,
                                        onPressed: () => launchUrl(Uri.parse(i.whatsappUrl!), mode: LaunchMode.externalApplication),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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
