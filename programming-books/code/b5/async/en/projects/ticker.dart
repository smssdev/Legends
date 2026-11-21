import 'dart:async';

Future<void> main() async {
  var prices = StreamController<int>.broadcast();

  // Two listeners on the same stream.
  var total = 0, count = 0;
  prices.stream.listen((p) => print('price: $p'));
  late StreamSubscription<int> averages;
  averages = prices.stream.listen((p) {
    total += p;
    count++;
    print('  average: ${(total / count).toStringAsFixed(1)}');
    // Stop listening after 5 prices.
    if (count == 5) averages.cancel();
  });

  for (var p in [45, 48, 44, 50, 52, 49]) {
    prices.add(p);
    await Future.delayed(Duration.zero);
  }
  await prices.close();
}
