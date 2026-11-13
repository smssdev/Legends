import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../core/api/intents.dart';
import 'sim_source.dart';

/// An order's state on the live screen: on its way, or refused with the server's words.
typedef OrderState = ({bool busy, String? error});

/// [Sprint 59 F5] The coach's orders in a live match (a substitution, the tactics, the formation): one at a time, one
/// key per order (Intents: a retry after a lost answer is the same order on the server), and the refusal kept for the
/// screen. The screen draws [state] and calls the actions.
class LiveOrders extends Notifier<OrderState> {
  LiveOrders(this.match);

  final int match;

  @override
  OrderState build() => (busy: false, error: null);

  /// True when the server took [order].
  Future<bool> send(Map<String, Object> order) async {
    if (state.busy) return false;
    state = (busy: true, error: null);
    try {
      await Intents.run('order:$match:$order', (key) => ref.read(matchSourceProvider(match)).order(match, order, key: key));
      state = (busy: false, error: null);
      return true;
    } on ApiError catch (e) {
      state = (busy: false, error: e.message);
      return false;
    }
  }

  Future<bool> sub(int out, int into) => send({'type': 'sub', 'out': out, 'in': into});
  Future<bool> tactics(Map<String, Object> changes) => send({'type': 'tactics', 'tactics': changes});
  Future<bool> formation(String formation) => send({'type': 'formation', 'formation': formation});
}

final liveOrdersProvider = NotifierProvider.autoDispose.family<LiveOrders, OrderState, int>(LiveOrders.new);
