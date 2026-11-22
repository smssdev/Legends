import 'money.dart';

class MenuItem {
  const MenuItem(this.id, this.price);

  final String id;
  final Money price;
}

const menu = [
  MenuItem('latte', Money(45)),
  MenuItem('tea', Money(25)),
  MenuItem('cake', Money(60)),
];

class OrderLine {
  const OrderLine(this.item, this.quantity);

  final MenuItem item;
  final int quantity;

  Money get total => item.price * quantity;
}

enum OrderStatus { pending, preparing, ready, cancelled }

// الطلب كما يراه العمل: لا JSON ولا Widgets.
class Order {
  const Order({
    required this.id,
    required this.lines,
    required this.status,
    required this.placedAt,
  });

  final int id;
  final List<OrderLine> lines;
  final OrderStatus status;
  final DateTime placedAt;

  Money get total =>
      lines.fold(const Money(0), (sum, line) => sum + line.total);
  int get items => lines.fold(0, (sum, line) => sum + line.quantity);
}
