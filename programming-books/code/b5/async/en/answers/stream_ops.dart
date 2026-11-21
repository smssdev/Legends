Future<void> main() async {
  var orders = Stream.fromIterable([45, 15, 20, 60, 15]);
  var big = await orders.where((p) => p >= 20).map((p) => p + 5).toList();
  print(big);
  var sum = await Stream.fromIterable([45, 15, 20]).fold(0, (s, p) => s + p);
  print(sum);
}
