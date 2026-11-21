class MenuItem {
  final String name;
  final int price;
  // معاملات مسماة كما في الفصل 2: الاستدعاء يقول أي قيمة لأي حقل.
  const MenuItem({required this.name, required this.price});

  // getter: يبدو كحقل، لكنه يُحسب في كل مرة.
  bool get isExpensive => price >= 50;
}

class Order {
  // _lines تبدأ بـ _: خاصة، لا يلمسها إلا هذا الملف.
  final List<MenuItem> _lines = [];

  // أضف سطراً إلى الطلب؛ والكمية تبدأ بـ 1.
  void add(MenuItem item, [int count = 1]) {
    for (var i = 0; i < count; i++) {
      _lines.add(item);
    }
  }

  int get count => _lines.length;
  int get total => _lines.fold(0, (sum, item) => sum + item.price);
}

void main() {
  const latte = MenuItem(name: 'لاتيه', price: 45);
  const cake = MenuItem(name: 'كيك', price: 60);
  print(cake.isExpensive);

  var order = Order();
  order.add(latte, 2);
  order.add(cake);
  print('${order.count} قطع, الإجمالي: ${order.total} جنيه');
}
