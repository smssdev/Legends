// الثواني منذ بداية main، بأعشار الثانية: النتيجة نفسها على كل جهاز.
final watch = Stopwatch();
String clock() => '${(watch.elapsedMilliseconds / 1000).toStringAsFixed(1)} ث';

// Future<String>: نص سيكون جاهزاً لاحقاً.
Future<String> brew(String drink) {
  return Future.delayed(Duration(milliseconds: 300), () => '$drink جاهز');
}

void main() {
  watch.start();
  print('${clock()} طلب');
  // then: ماذا تفعل بالقيمة حين تصل.
  brew('لاتيه').then((cup) => print('${clock()} $cup'));
  // main لا تنتظر: سطرها الأخير يعمل أولاً.
  print('${clock()} نهاية main');
}
