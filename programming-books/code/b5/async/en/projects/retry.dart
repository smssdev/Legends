// Seconds since main started, in tenths: the same on every machine.
final watch = Stopwatch();
String clock() => '${(watch.elapsedMilliseconds / 1000).toStringAsFixed(1)} s';

var calls = 0;

// Fails the first two times, as a server sometimes does.
Future<String> fetchMenu() async {
  await Future.delayed(Duration(milliseconds: 100));
  calls++;
  if (calls < 3) throw Exception('server busy');
  return 'the menu of the day';
}

// Try again, waiting twice as long each time.
Future<T> retry<T>(
  Future<T> Function() task, {
  int attempts = 4,
  int waitMs = 200,
}) async {
  for (var i = 1; ; i++) {
    try {
      return await task();
    } catch (e) {
      print('${clock()} attempt $i failed: $e');
      if (i == attempts) rethrow;
      print('${clock()} waiting ${waitMs / 1000} s');
      await Future.delayed(Duration(milliseconds: waitMs));
      waitMs *= 2;
    }
  }
}

Future<void> main() async {
  watch.start();
  var menu = await retry(fetchMenu);
  print('${clock()} got: $menu');
}
