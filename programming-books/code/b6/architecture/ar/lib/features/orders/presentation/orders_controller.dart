import 'package:material_ui/material_ui.dart';

import '../../../core/result.dart';
import '../domain/failures.dart';
import '../domain/order.dart';
import '../domain/orders_repository.dart';
import '../domain/place_order.dart';

// حالة الشاشة وأفعالها. يستدعي حالة الاستخدام، ويحوّل حالات الفشل إلى كلمات.
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
        message = 'أُرسل الطلب: الطلب ${value.id}';
        history = await repository.history();
      case Err(:final failure):
        message = describe(failure);
    }
    placing = false;
    notifyListeners();
  }

  // كل فشل، بلغة الشخص.
  static String describe(OrderFailure failure) => switch (failure) {
    EmptyOrder() => 'أضف شيئاً إلى سلتك أولاً.',
    TooLarge() => 'الطلب الواحد يتسع لعشرين قطعة على الأكثر.',
    Closed() => 'المقهى مغلق. نفتح من 8:00 إلى 22:00.',
    NetworkFailure() => 'لا اتصال. سلتك محفوظة؛ حاول من جديد.',
  };
}
