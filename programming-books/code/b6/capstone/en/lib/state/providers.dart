import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/cafe_api.dart';
import '../data/menu_repository.dart';
import '../data/models.dart';

final apiProvider = Provider<CafeApi>((ref) => DemoApi());
final prefsProvider = Provider<SharedPreferencesAsync>(
  (ref) => SharedPreferencesAsync(),
);

final menuProvider = StreamProvider<(List<Drink>, {bool fresh})>(
  (ref) =>
      MenuRepository(ref.watch(apiProvider), ref.watch(prefsProvider)).watch(),
);

// The cart is plain state: a map from drink to count, and its total.
class Cart extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => {};

  void add(String id) => state = {...state, id: (state[id] ?? 0) + 1};

  void remove(String id) {
    final count = (state[id] ?? 0) - 1;
    state = {
      for (final MapEntry(:key, :value) in state.entries)
        if (key != id) key: value,
      if (count > 0) id: count,
    };
  }

  void clear() => state = {};
}

final cartProvider = NotifierProvider<Cart, Map<String, int>>(Cart.new);

int totalOf(Map<String, int> cart, List<Drink> menu) =>
    menu.fold(0, (sum, drink) => sum + drink.price * (cart[drink.id] ?? 0));

final orderProvider = FutureProvider.family<Order, String>(
  (ref, id) => ref.watch(apiProvider).order(id),
);
