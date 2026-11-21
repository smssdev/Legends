// الثواني منذ بداية main، بأعشار الثانية: النتيجة نفسها على كل جهاز.
final watch = Stopwatch();
String clock() => '${(watch.elapsedMilliseconds / 1000).toStringAsFixed(1)} ث';

Future<void> brew(int n) async {
  await Future.delayed(Duration(milliseconds: 300));
  print('${clock()} #$n جاهز');
}

// قهوتان على الأكثر في وقت واحد: مكان في الآلة لكل عامل.
Future<void> worker(List<int> queue, String name) async {
  while (queue.isNotEmpty) {
    var n = queue.removeAt(0);
    print('${clock()} الآلة $name: #$n');
    await brew(n);
  }
}

Future<void> main() async {
  watch.start();
  var queue = [1, 2, 3, 4, 5];
  await Future.wait([worker(queue, 'A'), worker(queue, 'B')]);
  print('${clock()} انتهى');
}
