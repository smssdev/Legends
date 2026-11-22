import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/order.dart';

// Immutable states make undo simple: keep the old ones.
class UndoBasket extends Notifier<Map<MenuItem, int>> {
  final _past = <Map<MenuItem, int>>[];

  @override
  Map<MenuItem, int> build() => const {};

  bool get canUndo => _past.isNotEmpty;

  void _set(Map<MenuItem, int> next) {
    _past.add(state);
    state = next;
  }

  void add(MenuItem item) => _set({...state, item: (state[item] ?? 0) + 1});

  void remove(MenuItem item) {
    final n = state[item] ?? 0;
    if (n == 0) {
      return;
    }
    _set(n == 1 ? ({...state}..remove(item)) : {...state, item: n - 1});
  }

  void undo() {
    if (canUndo) {
      state = _past.removeLast();
    }
  }
}

final undoBasketProvider = NotifierProvider<UndoBasket, Map<MenuItem, int>>(
  UndoBasket.new,
);
