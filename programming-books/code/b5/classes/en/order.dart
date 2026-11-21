class MenuItem {
  final String name;
  final int price;
  // Named parameters, as in Chapter 2: the call says which value is which.
  const MenuItem({required this.name, required this.price});

  // A getter: looks like a field, but is calculated each time.
  bool get isExpensive => price >= 50;
}

class Order {
  // _lines starts with _: private, only this file can touch it.
  final List<MenuItem> _lines = [];

  // Add one line to the order; the quantity starts at 1.
  void add(MenuItem item, [int count = 1]) {
    for (var i = 0; i < count; i++) {
      _lines.add(item);
    }
  }

  int get count => _lines.length;
  int get total => _lines.fold(0, (sum, item) => sum + item.price);
}

void main() {
  const latte = MenuItem(name: 'Latte', price: 45);
  const cake = MenuItem(name: 'Cake', price: 60);
  print(cake.isExpensive);

  var order = Order();
  order.add(latte, 2);
  order.add(cake);
  print('${order.count} items, Total: ${order.total} EGP');
}
