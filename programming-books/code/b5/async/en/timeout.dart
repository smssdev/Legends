import 'dart:async';

// Seconds since main started, in tenths: the same on every machine.
final watch = Stopwatch();
String clock() => '${(watch.elapsedMilliseconds / 1000).toStringAsFixed(1)} s';

Future<String> brew(String drink, int ms) =>
    Future.delayed(Duration(milliseconds: ms), () => '$drink ready');

Future<void> main() async {
  watch.start();
  for (var ms in [200, 800]) {
    try {
      // Wait at most 0.5 s, then give up.
      var cup = await brew('Latte', ms).timeout(Duration(milliseconds: 500));
      print('${clock()} $cup');
    } on TimeoutException {
      print('${clock()} too slow, cancelled after 0.5 s');
    }
  }
}
