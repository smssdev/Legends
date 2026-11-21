int twice(int n) => n * 2;

void main() {
  // A function is a value: it can be stored in a variable and passed to another function.
  var change = twice;
  print(change(21));

  // A function without a name, written where it is needed.
  var prices = [12, 30, 8, 45];
  var cheap = prices.where((p) => p < 20).toList();
  var doubled = prices.map(twice).toList();
  print(cheap);
  print(doubled);

  prices.forEach((p) {
    print('${p.toString().padLeft(3)} EGP');
  });
}
