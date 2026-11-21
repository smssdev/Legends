// الثواني منذ بداية main، بأعشار الثانية: النتيجة نفسها على كل جهاز.
final watch = Stopwatch();
String clock() => '${(watch.elapsedMilliseconds / 1000).toStringAsFixed(1)} ث';

Future<void> brew(String drink) async {
  await Future.delayed(Duration(milliseconds: 300));
  print('${clock()} $drink جاهز');
}

Future<void> main() async {
  watch.start();
  // بلا await: يُطبع الطلب قبل أن تجهز القهوة.
  brew('لاتيه');
  print('${clock()} قُدّم');
}
