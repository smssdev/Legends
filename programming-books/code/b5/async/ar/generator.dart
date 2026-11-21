// الثواني منذ بداية main، بأعشار الثانية: النتيجة نفسها على كل جهاز.
final watch = Stopwatch();
String clock() => '${(watch.elapsedMilliseconds / 1000).toStringAsFixed(1)} ث';

// async*: دالة تُخرج قيماً عبر الوقت، على شكل Stream.
Stream<int> countdown(int from) async* {
  for (var i = from; i > 0; i--) {
    await Future.delayed(Duration(milliseconds: 200));
    // yield ترسل قيمة واحدة لمن يستمع.
    yield i;
  }
}

Future<void> main() async {
  watch.start();
  await for (var n in countdown(3)) {
    print('${clock()} الصعود بعد $n');
  }
  print('${clock()} انتهى');
}
