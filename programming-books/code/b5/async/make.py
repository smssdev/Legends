"""Writes the examples of Book 5, chapter "Async Dart: Futures and Streams", in English and Arabic, and
runs every one of them.
Run: python3 make.py   (needs Dart 3.14, which comes with Flutter 3.50.1)

Bit's café learns to wait: coffee that takes time, two orders at once, a machine that breaks, a kitchen
fed by a stream of orders. Times are printed in tenths of a second (clock() in each file), so a run on
any machine prints the same thing. Projects in projects/, exercise answers in answers/.
"""
import re
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import dart_examples  # noqa: E402

T = {
    "en": dict(
        w_latte="Latte", w_tea="Tea", w_cake="Cake", w_cookie="Cookie", w_ready="ready",
        w_s="s", w_comma=",",
        w_order="order", w_start="start", w_end="end", w_one="one", w_two="two", w_three="three",
        w_later="later", w_now="now",
        w_c_clock="Seconds since main started, in tenths: the same on every machine.",
        w_c_future="A Future<String>: a String that will be ready later.",
        w_c_then="then: what to do with the value when it arrives.",
        w_c_main="main does not wait: its last line runs first.",
        w_c_await="await waits for the value, without blocking anything else.",
        w_c_seq="One after the other: the waits add up.",
        w_c_wait="Both at once: Future.wait waits for all of them.",
        w_c_ex="Our own error, with a message for people.",
        w_milk="No milk left", w_c_try="An error in a future arrives at the await, so try catches it.",
        w_c_finally="finally runs either way: clean the machine.",
        w_cleaned="machine cleaned", w_sorry="Sorry:",
        w_c_forgot="No await: the order is printed before the coffee is ready.",
        w_served="served", w_c_timeout="Wait at most 0.5 s, then give up.", w_too_slow="too slow, cancelled after",
        w_c_periodic="A Stream: a value every 0.2 s, and only the first 4.",
        w_c_awaitfor="await for: a loop that waits for each value.",
        w_c_listen="listen: a function called for every value; the program goes on.",
        w_c_ops="Streams have where and map too, like lists.",
        w_tick="tick", w_done="done",
        w_c_controller="A StreamController: the café decides when to send each value.",
        w_c_broadcast="broadcast: more than one listener may listen.",
        w_screen="screen", w_kitchen="kitchen", w_table="table", w_closed="closed",
        w_c_gen="async*: a function that yields values over time, as a Stream.",
        w_c_yield="yield sends one value to whoever is listening.",
        w_boarding="boarding in",
        w_c_kitchen="Each item takes its own time to prepare.",
        w_c_orders="Orders arrive one by one, as a stream.",
        w_c_parallel="The items of one order are prepared at the same time.",
        w_c_close="No more orders: close the stream, so await for can end.",
        w_arrived="arrives", w_all_ready="all ready",
        # Projects
        w_liftoff="Lift off!", w_c_count="One value per second, from the number given down to 1.",
        w_attempt="attempt", w_failed="failed", w_got="got", w_wait="waiting",
        w_c_flaky="Fails the first two times, as a server sometimes does.",
        w_c_retry="Try again, waiting twice as long each time.",
        w_gave_up="gave up after", w_attempts="attempts",
        w_menu="the menu of the day", w_server_busy="server busy",
        w_price="price", w_average="average", w_c_ticker="Two listeners on the same stream.",
        w_c_stop="Stop listening after 5 prices.",
        # Answers
        w_c_pool="At most two coffees at a time: one machine slot per worker.",
        w_machine="machine",
    ),
    "ar": dict(
        w_latte="لاتيه", w_tea="شاي", w_cake="كيك", w_cookie="كوكيز", w_ready="جاهز",
        w_s="ث", w_comma="،",
        w_order="طلب", w_start="بداية", w_end="نهاية", w_one="واحد", w_two="اثنان", w_three="ثلاثة",
        w_later="لاحقاً", w_now="الآن",
        w_c_clock="الثواني منذ بداية main، بأعشار الثانية: النتيجة نفسها على كل جهاز.",
        w_c_future="Future<String>: نص سيكون جاهزاً لاحقاً.",
        w_c_then="then: ماذا تفعل بالقيمة حين تصل.",
        w_c_main="main لا تنتظر: سطرها الأخير يعمل أولاً.",
        w_c_await="await تنتظر القيمة، دون أن توقف أي شيء آخر.",
        w_c_seq="واحداً بعد الآخر: أوقات الانتظار تُجمع.",
        w_c_wait="الاثنان معاً: Future.wait تنتظرها كلها.",
        w_c_ex="خطأ من صنعنا، برسالة يفهمها الناس.",
        w_milk="نفد الحليب", w_c_try="الخطأ في الـ Future يصل عند await، فتلتقطه try.",
        w_c_finally="finally تعمل في الحالتين: نظّف الآلة.",
        w_cleaned="نُظّفت الآلة", w_sorry="نعتذر:",
        w_c_forgot="بلا await: يُطبع الطلب قبل أن تجهز القهوة.",
        w_served="قُدّم", w_c_timeout="انتظر 0.5 ث على الأكثر، ثم استسلم.", w_too_slow="بطيء جداً، أُلغي بعد",
        w_c_periodic="Stream: قيمة كل 0.2 ث، والأربع الأولى فقط.",
        w_c_awaitfor="await for: حلقة تنتظر كل قيمة.",
        w_c_listen="listen: دالة تُستدعى لكل قيمة؛ والبرنامج يكمل.",
        w_c_ops="للـ Stream أيضاً where وmap، كالقوائم.",
        w_tick="نبضة", w_done="انتهى",
        w_c_controller="StreamController: المقهى يقرر متى يرسل كل قيمة.",
        w_c_broadcast="broadcast: يمكن لأكثر من مستمع أن يستمع.",
        w_screen="الشاشة", w_kitchen="المطبخ", w_table="طاولة", w_closed="أُغلق",
        w_c_gen="async*: دالة تُخرج قيماً عبر الوقت، على شكل Stream.",
        w_c_yield="yield ترسل قيمة واحدة لمن يستمع.",
        w_boarding="الصعود بعد",
        w_c_kitchen="لكل صنف وقت تحضير خاص به.",
        w_c_orders="الطلبات تصل واحداً بعد الآخر، على شكل Stream.",
        w_c_parallel="أصناف الطلب الواحد تُحضّر في الوقت نفسه.",
        w_c_close="لا طلبات أخرى: أغلق الـ Stream، لتنتهي await for.",
        w_arrived="يصل", w_all_ready="كله جاهز",
        w_liftoff="انطلق!", w_c_count="قيمة كل ثانية، من الرقم المعطى نزولاً إلى 1.",
        w_attempt="المحاولة", w_failed="فشلت", w_got="وصل", w_wait="انتظار",
        w_c_flaky="تفشل أول مرتين، كما يفعل الخادم أحياناً.",
        w_c_retry="حاول من جديد، وانتظر ضعف المدة في كل مرة.",
        w_gave_up="استسلمنا بعد", w_attempts="محاولات",
        w_menu="قائمة اليوم", w_server_busy="الخادم مشغول",
        w_price="السعر", w_average="المتوسط", w_c_ticker="مستمعان على الـ Stream نفسه.",
        w_c_stop="توقف عن الاستماع بعد 5 أسعار.",
        w_c_pool="قهوتان على الأكثر في وقت واحد: مكان في الآلة لكل عامل.",
        w_machine="الآلة",
    ),
}

# Every file that prints times starts with the same small clock.
CLOCK = """// {w_c_clock}
final watch = Stopwatch();
String clock() => '${(watch.elapsedMilliseconds / 1000).toStringAsFixed(1)} {w_s}';
"""

FILES = {
    "order.dart": """void main() {
  print('{w_one}');
  Future.delayed(Duration(milliseconds: 100), () => print('{w_three}'));
  print('{w_two}');
}
""",
    "future.dart": CLOCK + """
// {w_c_future}
Future<String> brew(String drink) {
  return Future.delayed(Duration(milliseconds: 300), () => '$drink {w_ready}');
}

void main() {
  print('${clock()} {w_order}');
  // {w_c_then}
  brew('{w_latte}').then((cup) => print('${clock()} $cup'));
  // {w_c_main}
  print('${clock()} {w_end} {w_of_main}');
}
""",
    "await.dart": CLOCK + """
Future<String> brew(String drink) =>
    Future.delayed(Duration(milliseconds: 300), () => '$drink {w_ready}');

Future<void> main() async {
  // {w_c_await}
  var cup = await brew('{w_latte}');
  print('${clock()} $cup');

  // {w_c_seq}
  var a = await brew('{w_tea}');
  var b = await brew('{w_latte}');
  print('${clock()} $a{w_comma} $b');

  // {w_c_wait}
  var both = await Future.wait([brew('{w_tea}'), brew('{w_latte}')]);
  print('${clock()} $both');
}
""",
    "errors.dart": """// {w_c_ex}
class OutOfMilk implements Exception {
  final String drink;
  OutOfMilk(this.drink);

  @override
  String toString() => '{w_milk} ($drink)';
}

Future<String> brew(String drink) async {
  await Future.delayed(Duration(milliseconds: 100));
  if (drink == '{w_latte}') throw OutOfMilk(drink);
  return '$drink {w_ready}';
}

Future<void> serve(String drink) async {
  // {w_c_try}
  try {
    var cup = await brew(drink);
    print(cup);
  } on OutOfMilk catch (e) {
    print('{w_sorry} $e');
  } finally {
    // {w_c_finally}
    print('  {w_cleaned}');
  }
}

Future<void> main() async {
  await serve('{w_tea}');
  await serve('{w_latte}');
}
""",
    "forgot-await.dart": CLOCK + """
Future<void> brew(String drink) async {
  await Future.delayed(Duration(milliseconds: 300));
  print('${clock()} $drink {w_ready}');
}

Future<void> main() async {
  // {w_c_forgot}
  brew('{w_latte}');
  print('${clock()} {w_served}');
}
""",
    "timeout.dart": "import 'dart:async';\n\n" + CLOCK + """
Future<String> brew(String drink, int ms) =>
    Future.delayed(Duration(milliseconds: ms), () => '$drink {w_ready}');

Future<void> main() async {
  for (var ms in [200, 800]) {
    try {
      // {w_c_timeout}
      var cup = await brew('{w_latte}', ms).timeout(Duration(milliseconds: 500));
      print('${clock()} $cup');
    } on TimeoutException {
      print('${clock()} {w_too_slow} 0.5 {w_s}');
    }
  }
}
""",
    "streams.dart": CLOCK + """
Future<void> main() async {
  // {w_c_periodic}
  var ticks = Stream.periodic(Duration(milliseconds: 200), (i) => i + 1).take(4);

  // {w_c_awaitfor}
  await for (var t in ticks) {
    print('${clock()} {w_tick} $t');
  }

  // {w_c_ops}
  var prices = Stream.fromIterable([45, 15, 20, 60]);
  var dear = await prices.where((p) => p > 18).map((p) => p * 2).toList();
  print(dear);

  // {w_c_listen}
  Stream.fromIterable(['{w_tea}', '{w_cake}']).listen((item) => print('{w_later}: $item'));
  print('{w_now}');
}
""",
    "controller.dart": """import 'dart:async';

Future<void> main() async {
  // {w_c_controller}
  // {w_c_broadcast}
  var orders = StreamController<String>.broadcast();

  orders.stream.listen((o) => print('{w_screen}: $o'));
  orders.stream.where((o) => o.contains('{w_cake}')).listen((o) => print('{w_kitchen}: $o'));

  orders.add('{w_table} 1: {w_latte}');
  orders.add('{w_table} 2: {w_cake}');
  orders.add('{w_table} 3: {w_tea}{w_comma} {w_cake}');
  await orders.close();
  print('{w_closed}');
}
""",
    "generator.dart": CLOCK + """
// {w_c_gen}
Stream<int> countdown(int from) async* {
  for (var i = from; i > 0; i--) {
    await Future.delayed(Duration(milliseconds: 200));
    // {w_c_yield}
    yield i;
  }
}

Future<void> main() async {
  await for (var n in countdown(3)) {
    print('${clock()} {w_boarding} $n');
  }
  print('${clock()} {w_done}');
}
""",
    "kitchen.dart": "import 'dart:async';\n\n" + CLOCK + """
// {w_c_kitchen}
const prepTime = {'{w_latte}': 300, '{w_tea}': 100, '{w_cake}': 200, '{w_cookie}': 100};

Future<String> prepare(String item) async {
  await Future.delayed(Duration(milliseconds: prepTime[item] ?? 100));
  return item;
}

// {w_c_orders}
Stream<List<String>> incoming() async* {
  yield ['{w_latte}', '{w_cake}'];
  await Future.delayed(Duration(milliseconds: 100));
  yield ['{w_tea}'];
  await Future.delayed(Duration(milliseconds: 100));
  yield ['{w_cookie}', '{w_tea}', '{w_latte}'];
}

Future<void> main() async {
  var n = 0;
  var kitchen = <Future<void>>[];
  await for (var items in incoming()) {
    var number = ++n;
    print('${clock()} {w_order} $number {w_arrived}: ${items.join('{w_comma} ')}');
    // {w_c_parallel}
    kitchen.add(
      Future.wait(items.map(prepare)).then(
        (done) => print('${clock()} {w_order} $number {w_ready}'),
      ),
    );
  }
  await Future.wait(kitchen);
  print('${clock()} {w_all_ready}');
}
""",
}
T["en"]["w_of_main"] = "of main"
T["ar"]["w_of_main"] = "main"

PROJECTS = {
    "projects/countdown.dart": """// {w_c_count}
Stream<int> countdown(int from) async* {
  for (var i = from; i >= 1; i--) {
    yield i;
    await Future.delayed(Duration(milliseconds: 1000));
  }
}

Future<void> main() async {
  await for (var n in countdown(5)) {
    print(n);
  }
  print('{w_liftoff}');
}
""",
    "projects/retry.dart": CLOCK + """
var calls = 0;

// {w_c_flaky}
Future<String> fetchMenu() async {
  await Future.delayed(Duration(milliseconds: 100));
  calls++;
  if (calls < 3) throw Exception('{w_server_busy}');
  return '{w_menu}';
}

// {w_c_retry}
Future<T> retry<T>(Future<T> Function() task, {int attempts = 4, int waitMs = 200}) async {
  for (var i = 1; ; i++) {
    try {
      return await task();
    } catch (e) {
      print('${clock()} {w_attempt} $i {w_failed}: $e');
      if (i == attempts) rethrow;
      print('${clock()} {w_wait} ${waitMs / 1000} {w_s}');
      await Future.delayed(Duration(milliseconds: waitMs));
      waitMs *= 2;
    }
  }
}

Future<void> main() async {
  var menu = await retry(fetchMenu);
  print('${clock()} {w_got}: $menu');
}
""",
    "projects/ticker.dart": """import 'dart:async';

Future<void> main() async {
  var prices = StreamController<int>.broadcast();

  // {w_c_ticker}
  var total = 0, count = 0;
  prices.stream.listen((p) => print('{w_price}: $p'));
  late StreamSubscription<int> averages;
  averages = prices.stream.listen((p) {
    total += p;
    count++;
    print('  {w_average}: ${(total / count).toStringAsFixed(1)}');
    // {w_c_stop}
    if (count == 5) averages.cancel();
  });

  for (var p in [45, 48, 44, 50, 52, 49]) {
    prices.add(p);
    await Future.delayed(Duration.zero);
  }
  await prices.close();
}
""",
}

ANSWERS = {
    "answers/order.dart": """Future<void> main() async {
  print('A');
  Future(() => print('B'));
  Future.delayed(Duration(milliseconds: 50), () => print('C'));
  print('D');
  await Future.delayed(Duration(milliseconds: 100));
  print('E');
}
""",
    "answers/instance.dart": """Future<String> fetchName() async => 'Bit';

Future<void> main() async {
  var name = fetchName();
  print(name);
  print(await fetchName());
}
""",
    "answers/then_chain.dart": """Future<int> price(String item) async => item.length * 10;

Future<int> withService(int p) async => p + p ~/ 10;

void withThen() {
  price('latte').then(withService).then((total) => print('then: $total'));
}

Future<void> withAwait() async {
  var p = await price('latte');
  var total = await withService(p);
  print('await: $total');
}

Future<void> main() async {
  withThen();
  await withAwait();
}
""",
    "answers/stream_ops.dart": """Future<void> main() async {
  var orders = Stream.fromIterable([45, 15, 20, 60, 15]);
  var big = await orders.where((p) => p >= 20).map((p) => p + 5).toList();
  print(big);
  var sum = await Stream.fromIterable([45, 15, 20]).fold(0, (s, p) => s + p);
  print(sum);
}
""",
    "answers/pool.dart": CLOCK + """
Future<void> brew(int n) async {
  await Future.delayed(Duration(milliseconds: 300));
  print('${clock()} #$n {w_ready}');
}

// {w_c_pool}
Future<void> worker(List<int> queue, String name) async {
  while (queue.isNotEmpty) {
    var n = queue.removeAt(0);
    print('${clock()} {w_machine} $name: #$n');
    await brew(n);
  }
}

Future<void> main() async {
  var queue = [1, 2, 3, 4, 5];
  await Future.wait([worker(queue, 'A'), worker(queue, 'B')]);
  print('${clock()} {w_done}');
}
""",
}


def start_clock(src):
    """Files with the clock start it on the first line of main (see clock in the chapter)."""
    if not isinstance(src, str) or "Stopwatch()" not in src:
        return src
    return re.sub(r"(main\(\)(?: async)? \{\n)", r"\1  watch.start();\n", src, count=1)


def main():
    sources = {name: start_clock(src) for name, src in {**FILES, **PROJECTS, **ANSWERS}.items()}
    dart_examples(HERE, T, sources)


if __name__ == "__main__":
    main()
