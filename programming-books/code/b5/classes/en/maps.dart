void main() {
  // A Map: each key (a name) leads to one value (a quantity).
  var stock = <String, int>{'sugar': 40, 'milk': 12, 'cups': 200};
  print(stock['milk']);
  print(stock['beans']);

  // Looking up a key gives int?: the key may not be there.
  int beans = stock['beans'] ?? 0;
  print(beans);

  stock['beans'] = 5;
  // update changes a value; ifAbsent says what to do when the key is missing.
  stock.update('milk', (n) => n - 2);
  stock.update('water', (n) => n + 6, ifAbsent: () => 6);
  print(stock.length);
  print(stock.containsKey('sugar'));

  for (var entry in stock.entries) {
    print('${entry.key}: ${entry.value}');
  }
  stock.remove('cups');
  print(stock.keys.toList());
}
