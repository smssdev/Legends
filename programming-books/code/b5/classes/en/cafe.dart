enum Category { drink, food }

class MenuItem {
  final String name;
  final int price;
  final Category category;
  const MenuItem(this.name, this.price, this.category);
}

// The menu: a const list of const items, built once.
const menu = [
  MenuItem('Latte', 45, Category.drink),
  MenuItem('Tea', 15, Category.drink),
  MenuItem('Cookie', 20, Category.food),
  MenuItem('Cake', 60, Category.food),
];

class Order {
  final int table;
  // An order: how many of each item. A Map, because each item appears once.
  final Map<MenuItem, int> _counts = {};

  Order(this.table);

  void add(MenuItem item, {int count = 1}) {
    _counts.update(item, (n) => n + count, ifAbsent: () => count);
  }

  int get total {
    var sum = 0;
    _counts.forEach((item, n) => sum += item.price * n);
    return sum;
  }

  Set<Category> get categories => {
    for (var item in _counts.keys) item.category,
  };

  // One line per item, sorted by name, built with a for inside the list.
  List<String> get lines {
    var items = _counts.keys.toList()..sort((a, b) => a.name.compareTo(b.name));
    return [for (var item in items) '${_counts[item]} × ${item.name}'];
  }
}

void main() {
  var order = Order(4);
  order.add(menu[0], count: 2);
  order.add(menu[3]);
  order.add(menu[0]);
  order.add(menu[2], count: 3);

  print('Order, table ${order.table}');
  for (var line in order.lines) {
    print('  $line');
  }
  print('Total: ${order.total} EGP');
  print(order.categories.map((c) => c.name).toList());
}
