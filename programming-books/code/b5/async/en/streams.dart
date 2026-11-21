// Seconds since main started, in tenths: the same on every machine.
final watch = Stopwatch();
String clock() => '${(watch.elapsedMilliseconds / 1000).toStringAsFixed(1)} s';

Future<void> main() async {
  watch.start();
  // A Stream: a value every 0.2 s, and only the first 4.
  var ticks = Stream.periodic(
    Duration(milliseconds: 200),
    (i) => i + 1,
  ).take(4);

  // await for: a loop that waits for each value.
  await for (var t in ticks) {
    print('${clock()} tick $t');
  }

  // Streams have where and map too, like lists.
  var prices = Stream.fromIterable([45, 15, 20, 60]);
  var dear = await prices.where((p) => p > 18).map((p) => p * 2).toList();
  print(dear);

  // listen: a function called for every value; the program goes on.
  Stream.fromIterable(['Tea', 'Cake']).listen((item) => print('later: $item'));
  print('now');
}
