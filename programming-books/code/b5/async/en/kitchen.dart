import 'dart:async';

// Seconds since main started, in tenths: the same on every machine.
final watch = Stopwatch();
String clock() => '${(watch.elapsedMilliseconds / 1000).toStringAsFixed(1)} s';

// Each item takes its own time to prepare.
const prepTime = {'Latte': 300, 'Tea': 100, 'Cake': 200, 'Cookie': 100};

Future<String> prepare(String item) async {
  await Future.delayed(Duration(milliseconds: prepTime[item] ?? 100));
  return item;
}

// Orders arrive one by one, as a stream.
Stream<List<String>> incoming() async* {
  yield ['Latte', 'Cake'];
  await Future.delayed(Duration(milliseconds: 100));
  yield ['Tea'];
  await Future.delayed(Duration(milliseconds: 100));
  yield ['Cookie', 'Tea', 'Latte'];
}

Future<void> main() async {
  watch.start();
  var n = 0;
  var kitchen = <Future<void>>[];
  await for (var items in incoming()) {
    var number = ++n;
    print('${clock()} order $number arrives: ${items.join(', ')}');
    // The items of one order are prepared at the same time.
    kitchen.add(
      Future.wait(items.map(prepare))
          .then((done) => print('${clock()} order $number ready')),
    );
  }
  await Future.wait(kitchen);
  print('${clock()} all ready');
}
