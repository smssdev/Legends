import 'dart:async';

// الثواني منذ بداية main، بأعشار الثانية: النتيجة نفسها على كل جهاز.
final watch = Stopwatch();
String clock() => '${(watch.elapsedMilliseconds / 1000).toStringAsFixed(1)} ث';

Future<String> brew(String drink, int ms) =>
    Future.delayed(Duration(milliseconds: ms), () => '$drink جاهز');

Future<void> main() async {
  watch.start();
  for (var ms in [200, 800]) {
    try {
      // انتظر 0.5 ث على الأكثر، ثم استسلم.
      var cup = await brew('لاتيه', ms).timeout(Duration(milliseconds: 500));
      print('${clock()} $cup');
    } on TimeoutException {
      print('${clock()} بطيء جداً، أُلغي بعد 0.5 ث');
    }
  }
}
