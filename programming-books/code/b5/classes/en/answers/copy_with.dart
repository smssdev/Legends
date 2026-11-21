class MenuItem {
  final String name;
  final int price;
  const MenuItem({required this.name, required this.price});

  // copyWith: a new item like this one, with some fields changed.
  MenuItem copyWith({String? name, int? price}) =>
      MenuItem(name: name ?? this.name, price: price ?? this.price);

  @override
  String toString() => '$name ($price)';
}

void main() {
  const latte = MenuItem(name: 'Latte', price: 45);
  var friday = latte.copyWith(price: 36);
  print(latte);
  print(friday);
  print(latte.copyWith(name: 'Tea', price: 15));
}
