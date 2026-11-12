import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../core/api/intents.dart';
import 'market_data.dart';

/// A purchase's state on the screen: on its way, or refused with the server's words.
typedef BuyState = ({bool busy, String? error});

/// [Sprint 59 F5] Buying a player: one key per purchase the coach means (Intents), so a retry after a lost answer is
/// the same purchase on the server, and a refusal stays on the sheet. The sheet draws [state] and calls [buy].
class BuyController extends Notifier<BuyState> {
  BuyController(this.league);

  final int league;

  @override
  BuyState build() => (busy: false, error: null);

  /// True when the player is bought.
  Future<bool> buy(int player, {bool compensate = false}) async {
    if (state.busy) return false;
    state = (busy: true, error: null);
    try {
      await Intents.run(
        'buy:$league:$player:$compensate',
        (key) => ref.read(marketRepositoryProvider).buy(league, player, compensate: compensate, key: key),
      );
      state = (busy: false, error: null);
      return true;
    } on ApiError catch (e) {
      state = (busy: false, error: e.message);
      return false;
    }
  }
}

final buyControllerProvider = NotifierProvider.autoDispose.family<BuyController, BuyState, int>(BuyController.new);
