// الثواني منذ بداية main، بأعشار الثانية: النتيجة نفسها على كل جهاز.
final watch = Stopwatch();
String clock() => '${(watch.elapsedMilliseconds / 1000).toStringAsFixed(1)} ث';

var calls = 0;

// تفشل أول مرتين، كما يفعل الخادم أحياناً.
Future<String> fetchMenu() async {
  await Future.delayed(Duration(milliseconds: 100));
  calls++;
  if (calls < 3) throw Exception('الخادم مشغول');
  return 'قائمة اليوم';
}

// حاول من جديد، وانتظر ضعف المدة في كل مرة.
Future<T> retry<T>(
  Future<T> Function() task, {
  int attempts = 4,
  int waitMs = 200,
}) async {
  for (var i = 1; ; i++) {
    try {
      return await task();
    } catch (e) {
      print('${clock()} المحاولة $i فشلت: $e');
      if (i == attempts) rethrow;
      print('${clock()} انتظار ${waitMs / 1000} ث');
      await Future.delayed(Duration(milliseconds: waitMs));
      waitMs *= 2;
    }
  }
}

Future<void> main() async {
  watch.start();
  var menu = await retry(fetchMenu);
  print('${clock()} وصل: $menu');
}
