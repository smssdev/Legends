// Seconds since main started, in tenths: the same on every machine.
final watch = Stopwatch();
String clock() => '${(watch.elapsedMilliseconds / 1000).toStringAsFixed(1)} s';

// async*: a function that yields values over time, as a Stream.
Stream<int> countdown(int from) async* {
  for (var i = from; i > 0; i--) {
    await Future.delayed(Duration(milliseconds: 200));
    // yield sends one value to whoever is listening.
    yield i;
  }
}

Future<void> main() async {
  watch.start();
  await for (var n in countdown(3)) {
    print('${clock()} boarding in $n');
  }
  print('${clock()} done');
}
