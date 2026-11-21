class MenuItem {
  // Fields: what every menu item knows. final, because an item never changes.
  final String name;
  final int price;

  // The constructor: this.name puts the first argument straight into the field.
  const MenuItem(this.name, this.price);

  // A method: a function that belongs to the item and can use its fields.
  int priceFor(int count) => price * count;

  // What print shows for an item.
  @override
  String toString() => '$name ($price EGP)';
}

void main() {
  var latte = const MenuItem('Latte', 45);
  var cookie = const MenuItem('Cookie', 20);
  print(latte);
  print(latte.name);
  print(cookie.priceFor(3));
}
