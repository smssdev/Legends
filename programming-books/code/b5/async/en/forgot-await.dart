// Seconds since main started, in tenths: the same on every machine.
final watch = Stopwatch();
String clock() => '${(watch.elapsedMilliseconds / 1000).toStringAsFixed(1)} s';

Future<void> brew(String drink) async {
  await Future.delayed(Duration(milliseconds: 300));
  print('${clock()} $drink ready');
}

Future<void> main() async {
  watch.start();
  // No await: the order is printed before the coffee is ready.
  brew('Latte');
  print('${clock()} served');
}
