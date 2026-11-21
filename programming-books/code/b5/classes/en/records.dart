// A record: two values travel together, no class needed.
(int, int) cheapestAndDearest(List<int> prices) {
  var sorted = [...prices]..sort();
  return (sorted.first, sorted.last);
}

({String name, int price}) special() => (name: 'Cake', price: 50);

void main() {
  var prices = [45, 20, 60, 15];
  var result = cheapestAndDearest(prices);
  print(result);
  print(result.$1);

  // A pattern takes the record apart into two variables.
  var (low, high) = cheapestAndDearest(prices);
  print('cheapest: $low, most expensive: $high');

  var today = special();
  print('${today.name}: ${today.price}');
}
