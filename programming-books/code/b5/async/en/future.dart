// Seconds since main started, in tenths: the same on every machine.
final watch = Stopwatch();
String clock() => '${(watch.elapsedMilliseconds / 1000).toStringAsFixed(1)} s';

// A Future<String>: a String that will be ready later.
Future<String> brew(String drink) {
  return Future.delayed(Duration(milliseconds: 300), () => '$drink ready');
}

void main() {
  watch.start();
  print('${clock()} order');
  // then: what to do with the value when it arrives.
  brew('Latte').then((cup) => print('${clock()} $cup'));
  // main does not wait: its last line runs first.
  print('${clock()} end of main');
}
