import 'package:material_ui/material_ui.dart';

import '../../../core/result.dart';
import '../domain/failures.dart';
import '../domain/order.dart';
import '../domain/orders_repository.dart';
import '../domain/place_order.dart';

// The screen's state and actions. It calls the use case, and turns failures into words.
class OrdersController extends ChangeNotifier {
  OrdersController(this.placeOrder, this.repository);

  final PlaceOrder placeOrder;
  final OrdersRepository repository;

  final basket = <MenuItem, int>{};
  var history = <Order>[];
  var placing = false;
  String? message;

  void add(MenuItem item) {
    basket[item] = (basket[item] ?? 0) + 1;
    message = null;
    notifyListeners();
  }

  Future<void> place() async {
    placing = true;
    notifyListeners();
    final result = await placeOrder([
      for (final e in basket.entries) OrderLine(e.key, e.value),
    ]);
    switch (result) {
      case Ok(:final value):
        basket.clear();
        message = 'Order placed: Order ${value.id}';
        history = await repository.history();
      case Err(:final failure):
        message = describe(failure);
    }
    placing = false;
    notifyListeners();
  }

  // Each failure, in the person's language.
  static String describe(OrderFailure failure) => switch (failure) {
    EmptyOrder() => 'Add something to your basket first.',
    TooLarge() => 'One order can hold at most 20 items.',
    Closed() => 'The café is closed. We open from 8:00 to 22:00.',
    NetworkFailure() => 'No connection. Your basket is kept; try again.',
  };
}
