// Seconds since main started, in tenths: the same on every machine.
final watch = Stopwatch();
String clock() => '${(watch.elapsedMilliseconds / 1000).toStringAsFixed(1)} s';

Future<String> brew(String drink) =>
    Future.delayed(Duration(milliseconds: 300), () => '$drink ready');

Future<void> main() async {
  watch.start();
  // await waits for the value, without blocking anything else.
  var cup = await brew('Latte');
  print('${clock()} $cup');

  // One after the other: the waits add up.
  var a = await brew('Tea');
  var b = await brew('Latte');
  print('${clock()} $a, $b');

  // Both at once: Future.wait waits for all of them.
  var both = await Future.wait([brew('Tea'), brew('Latte')]);
  print('${clock()} $both');
}
