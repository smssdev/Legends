// Seconds since main started, in tenths: the same on every machine.
final watch = Stopwatch();
String clock() => '${(watch.elapsedMilliseconds / 1000).toStringAsFixed(1)} s';

Future<void> brew(int n) async {
  await Future.delayed(Duration(milliseconds: 300));
  print('${clock()} #$n ready');
}

// At most two coffees at a time: one machine slot per worker.
Future<void> worker(List<int> queue, String name) async {
  while (queue.isNotEmpty) {
    var n = queue.removeAt(0);
    print('${clock()} machine $name: #$n');
    await brew(n);
  }
}

Future<void> main() async {
  watch.start();
  var queue = [1, 2, 3, 4, 5];
  await Future.wait([worker(queue, 'A'), worker(queue, 'B')]);
  print('${clock()} done');
}
