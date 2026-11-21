import 'dart:async';

// الثواني منذ بداية main، بأعشار الثانية: النتيجة نفسها على كل جهاز.
final watch = Stopwatch();
String clock() => '${(watch.elapsedMilliseconds / 1000).toStringAsFixed(1)} ث';

// لكل صنف وقت تحضير خاص به.
const prepTime = {'لاتيه': 300, 'شاي': 100, 'كيك': 200, 'كوكيز': 100};

Future<String> prepare(String item) async {
  await Future.delayed(Duration(milliseconds: prepTime[item] ?? 100));
  return item;
}

// الطلبات تصل واحداً بعد الآخر، على شكل Stream.
Stream<List<String>> incoming() async* {
  yield ['لاتيه', 'كيك'];
  await Future.delayed(Duration(milliseconds: 100));
  yield ['شاي'];
  await Future.delayed(Duration(milliseconds: 100));
  yield ['كوكيز', 'شاي', 'لاتيه'];
}

Future<void> main() async {
  watch.start();
  var n = 0;
  var kitchen = <Future<void>>[];
  await for (var items in incoming()) {
    var number = ++n;
    print('${clock()} طلب $number يصل: ${items.join('، ')}');
    // أصناف الطلب الواحد تُحضّر في الوقت نفسه.
    kitchen.add(
      Future.wait(items.map(prepare))
          .then((done) => print('${clock()} طلب $number جاهز')),
    );
  }
  await Future.wait(kitchen);
  print('${clock()} كله جاهز');
}
