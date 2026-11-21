enum Category { drink, food }

class MenuItem {
  final String name;
  final int price;
  final Category category;
  const MenuItem(this.name, this.price, this.category);
}

// القائمة: قائمة const من أصناف const، تُبنى مرة واحدة.
const menu = [
  MenuItem('لاتيه', 45, Category.drink),
  MenuItem('شاي', 15, Category.drink),
  MenuItem('كوكيز', 20, Category.food),
  MenuItem('كيك', 60, Category.food),
];

class Order {
  final int table;
  // الطلب: كم قطعة من كل صنف. Map، لأن كل صنف يظهر مرة واحدة.
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

  // سطر لكل صنف، مرتبة بالاسم، تبنيها for داخل القائمة.
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

  print('طلب، طاولة ${order.table}');
  for (var line in order.lines) {
    print('  $line');
  }
  print('الإجمالي: ${order.total} جنيه');
  print(order.categories.map((c) => c.name).toList());
}
