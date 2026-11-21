import 'dart:async';

Future<void> main() async {
  var prices = StreamController<int>.broadcast();

  // مستمعان على الـ Stream نفسه.
  var total = 0, count = 0;
  prices.stream.listen((p) => print('السعر: $p'));
  late StreamSubscription<int> averages;
  averages = prices.stream.listen((p) {
    total += p;
    count++;
    print('  المتوسط: ${(total / count).toStringAsFixed(1)}');
    // توقف عن الاستماع بعد 5 أسعار.
    if (count == 5) averages.cancel();
  });

  for (var p in [45, 48, 44, 50, 52, 49]) {
    prices.add(p);
    await Future.delayed(Duration.zero);
  }
  await prices.close();
}
