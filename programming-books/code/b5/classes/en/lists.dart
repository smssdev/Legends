void main() {
  // A List<int>: only ints may go in.
  var prices = <int>[45, 20, 60];
  prices.add(15);
  print(prices);
  print(prices[0]);
  print(prices.length);
  print(prices.contains(60));

  prices.remove(20);
  prices.sort();
  print(prices);

  // ... spreads one list inside another; if and for work inside a list too.
  var isFriday = true;
  var extras = [5, 10];
  var all = [
    ...prices,
    ...extras,
    if (isFriday) 0,
    for (var p in prices) p * 2,
  ];
  print(all);

  // fold carries a running total through the list.
  var total = prices.fold(0, (sum, p) => sum + p);
  print(total);
  print(prices.where((p) => p > 20).map((p) => '$p EGP').toList());
}
