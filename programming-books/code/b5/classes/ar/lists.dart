void main() {
  // List<int>: لا يدخلها إلا int.
  var prices = <int>[45, 20, 60];
  prices.add(15);
  print(prices);
  print(prices[0]);
  print(prices.length);
  print(prices.contains(60));

  prices.remove(20);
  prices.sort();
  print(prices);

  // ... تفرد قائمة داخل أخرى؛ وif وfor تعملان داخل القائمة أيضاً.
  var isFriday = true;
  var extras = [5, 10];
  var all = [
    ...prices,
    ...extras,
    if (isFriday) 0,
    for (var p in prices) p * 2,
  ];
  print(all);

  // fold تحمل مجموعاً متراكماً عبر القائمة.
  var total = prices.fold(0, (sum, p) => sum + p);
  print(total);
  print(prices.where((p) => p > 20).map((p) => '$p جنيه').toList());
}
