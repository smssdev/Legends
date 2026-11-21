// الثواني منذ بداية main، بأعشار الثانية: النتيجة نفسها على كل جهاز.
final watch = Stopwatch();
String clock() => '${(watch.elapsedMilliseconds / 1000).toStringAsFixed(1)} ث';

Future<String> brew(String drink) =>
    Future.delayed(Duration(milliseconds: 300), () => '$drink جاهز');

Future<void> main() async {
  watch.start();
  // await تنتظر القيمة، دون أن توقف أي شيء آخر.
  var cup = await brew('لاتيه');
  print('${clock()} $cup');

  // واحداً بعد الآخر: أوقات الانتظار تُجمع.
  var a = await brew('شاي');
  var b = await brew('لاتيه');
  print('${clock()} $a، $b');

  // الاثنان معاً: Future.wait تنتظرها كلها.
  var both = await Future.wait([brew('شاي'), brew('لاتيه')]);
  print('${clock()} $both');
}
