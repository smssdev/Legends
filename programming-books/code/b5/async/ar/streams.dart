// الثواني منذ بداية main، بأعشار الثانية: النتيجة نفسها على كل جهاز.
final watch = Stopwatch();
String clock() => '${(watch.elapsedMilliseconds / 1000).toStringAsFixed(1)} ث';

Future<void> main() async {
  watch.start();
  // Stream: قيمة كل 0.2 ث، والأربع الأولى فقط.
  var ticks = Stream.periodic(
    Duration(milliseconds: 200),
    (i) => i + 1,
  ).take(4);

  // await for: حلقة تنتظر كل قيمة.
  await for (var t in ticks) {
    print('${clock()} نبضة $t');
  }

  // للـ Stream أيضاً where وmap، كالقوائم.
  var prices = Stream.fromIterable([45, 15, 20, 60]);
  var dear = await prices.where((p) => p > 18).map((p) => p * 2).toList();
  print(dear);

  // listen: دالة تُستدعى لكل قيمة؛ والبرنامج يكمل.
  Stream.fromIterable(['شاي', 'كيك']).listen((item) => print('لاحقاً: $item'));
  print('الآن');
}
