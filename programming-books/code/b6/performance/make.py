"""Writes the examples of Book 6, chapter "Performance: Jank, Memory and Startup", in English and Arabic.
Every number in the chapter comes from these tests: widgets rebuilt by a tap, items built by a list, bytes
taken by a decoded photo, paints saved by a RepaintBoundary, frames lost while parsing JSON, and the time
to start an app.
Run: python3 make.py   (needs Flutter 3.50.1, Node.js, Playwright's Chromium and Pillow)
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent.parent / "b5"))
from kit import flutter_gallery  # noqa: E402

T = {
    "en": dict(
        w_rtl="",
        w_menu="Menu", w_order="Your order", w_add="Add", w_loading="Getting the menu ready", w_drink="Drink",
        w_egp="EGP",
        w_c_slow="Slow: the whole page is rebuilt for one number.",
        w_c_fast="Fast: only the badge listens to the count.",
        w_c_const="The list does not depend on the count: built once, then left alone.",
        w_c_cache="Decode the photo at the size it is shown, not at the size it was taken.",
        w_c_builder="Only the rows on screen, and a few around them, are ever built.",
        w_c_parallel="The three steps do not depend on each other: start them together.",
        w_c_first="Show something at once; load the rest behind it.",
        w_c_standin="Stand-ins for real work: reading settings, opening the database, fetching the menu.",
        w_c_boundary="The spinner repaints sixty times a second; the boundary keeps the chart out of it.",
        w_t_rebuilds="one tap, how many rows are rebuilt",
        w_t_image="the memory of a decoded photo",
        w_t_startup="three steps, one after the other or together",
        w_t_list="a list of 1000 drinks, how many rows are built",
        w_t_isolate="frames lost while parsing a big JSON",
        w_t_repaint="sixty frames of a spinner, how many times the chart is painted",
    ),
    "ar": dict(
        w_rtl="// من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.\n"
              "builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),\n",
        w_menu="القائمة", w_order="طلبك", w_add="أضف", w_loading="نجهّز القائمة", w_drink="مشروب",
        w_egp="جنيه",
        w_c_slow="بطيء: تُعاد بناء الصفحة كلها من أجل رقم واحد.",
        w_c_fast="سريع: الشارة وحدها تستمع إلى العدد.",
        w_c_const="القائمة لا تعتمد على العدد: تُبنى مرة ثم تُترك.",
        w_c_cache="فُكّ الصورة بالحجم الذي تُعرض به، لا بالحجم الذي التُقطت به.",
        w_c_builder="لا يُبنى إلا ما على الشاشة من صفوف، وقليل حولها.",
        w_c_parallel="الخطوات الثلاث لا تعتمد على بعضها: ابدأها معاً.",
        w_c_first="اعرض شيئاً فوراً؛ وحمّل الباقي خلفه.",
        w_c_standin="بدائل لعمل حقيقي: قراءة الإعدادات، وفتح قاعدة البيانات، وجلب القائمة.",
        w_c_boundary="المؤشر يُعاد رسمه ستين مرة في الثانية؛ والحد يُبقي الرسم البياني خارج ذلك.",
        w_t_rebuilds="ضغطة واحدة، كم صفاً يُعاد بناؤه",
        w_t_image="ذاكرة صورة مفكوكة",
        w_t_startup="ثلاث خطوات، واحدة بعد الأخرى أو معاً",
        w_t_list="قائمة من 1000 مشروب، كم صفاً يُبنى",
        w_t_isolate="الإطارات الضائعة أثناء تحليل JSON كبير",
        w_t_repaint="ستون إطاراً لمؤشر، كم مرة يُرسم الرسم البياني",
    ),
}

APP = """void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      {w_rtl}
      theme: ThemeData(colorSchemeSeed: Colors.brown),
      home: const %s(),
    ),
  );
}
"""

FILES = {
    "lib/rows.dart": """import 'package:material_ui/material_ui.dart';

var rowBuilds = 0;

class DrinkRow extends StatelessWidget {
  const DrinkRow({super.key, required this.n});

  final int n;

  @override
  Widget build(BuildContext context) {
    rowBuilds++;
    return ListTile(title: Text('{w_drink} $n'), trailing: Text('${40 + n % 5 * 5} {w_egp}'));
  }
}
""",
    "lib/order_slow.dart": """import 'package:material_ui/material_ui.dart';

import 'rows.dart';

// {w_c_slow}
class SlowOrderPage extends StatefulWidget {
  const SlowOrderPage({super.key});

  @override
  State<SlowOrderPage> createState() => _SlowOrderPageState();
}

class _SlowOrderPageState extends State<SlowOrderPage> {
  var count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{w_order}'), actions: [Badge.count(count: count, child: const Icon(Icons.local_cafe))]),
      body: SingleChildScrollView(
        child: Column(children: [for (var n = 1; n <= 30; n++) DrinkRow(n: n)]),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => setState(() => count++), child: const Icon(Icons.add)),
    );
  }
}
""",
    "lib/order_fast.dart": """import 'package:material_ui/material_ui.dart';

import 'rows.dart';

// {w_c_fast}
class FastOrderPage extends StatefulWidget {
  const FastOrderPage({super.key});

  @override
  State<FastOrderPage> createState() => _FastOrderPageState();
}

class _FastOrderPageState extends State<FastOrderPage> {
  final count = ValueNotifier(0);

  @override
  void dispose() {
    count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('{w_order}'),
        actions: [
          ValueListenableBuilder(
            valueListenable: count,
            builder: (context, value, child) => Badge.count(count: value, child: child),
            child: const Icon(Icons.local_cafe),
          ),
        ],
      ),
      body: const DrinkColumn(),
      floatingActionButton: FloatingActionButton(onPressed: () => count.value++, child: const Icon(Icons.add)),
    );
  }
}

// {w_c_const}
class DrinkColumn extends StatelessWidget {
  const DrinkColumn({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(children: [for (var n = 1; n <= 30; n++) DrinkRow(n: n)]),
  );
}
""",
    "test/rebuilds_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/order_fast.dart';
import 'package:bit_app/order_slow.dart';
import 'package:bit_app/rows.dart';

Future<int> rowsRebuiltByOneTap(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(MaterialApp(home: page));
  rowBuilds = 0;
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pump();
  expect(find.text('1'), findsOneWidget);
  return rowBuilds;
}

void main() {
  testWidgets('{w_t_rebuilds}', (tester) async {
    final slow = await rowsRebuiltByOneTap(tester, const SlowOrderPage());
    final fast = await rowsRebuiltByOneTap(tester, const FastOrderPage());
    debugPrint('rows rebuilt by one tap: slow page $slow, fast page $fast');
    expect(fast, 0);
  });
}
""",
    "lib/menu.dart": """import 'package:material_ui/material_ui.dart';

""" + APP % "MenuPage" + """
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = (56 * MediaQuery.devicePixelRatioOf(context)).round();
    return Scaffold(
      appBar: AppBar(title: const Text('{w_menu}')),
      // {w_c_builder}
      body: ListView.builder(
        itemCount: 1000,
        itemExtent: 72,
        itemBuilder: (context, i) => ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            // {w_c_cache}
            child: Image.asset('assets/photos/latte.jpg', width: 56, height: 56, fit: BoxFit.cover, cacheWidth: width),
          ),
          title: Text('{w_drink} ${i + 1}'),
          trailing: Text('${40 + i % 5 * 5} {w_egp}'),
        ),
      ),
    );
  }
}
""",
    "test/image_test.dart": """import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

String mb(int bytes) => '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';

Future<ui.Image> decode(Uint8List bytes, {int? width}) async {
  final codec = await ui.instantiateImageCodec(bytes, targetWidth: width);
  return (await codec.getNextFrame()).image;
}

void main() {
  testWidgets('{w_t_image}', (tester) async {
    await tester.runAsync(() async {
      final file = await File('assets/photos/latte.jpg').readAsBytes();
      final full = await decode(file);
      final small = await decode(file, width: 168);
      debugPrint('file on disk:            ${mb(file.length)}');
      debugPrint('decoded, full size:      ${full.width} x ${full.height}, ${mb(full.width * full.height * 4)}');
      debugPrint('decoded, cacheWidth 168: ${small.width} x ${small.height}, ${mb(small.width * small.height * 4)}');
    });
  });
}
""",
    "lib/startup.dart": """import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'menu.dart';

// {w_c_standin}
Future<void> readSettings() => Future.delayed(const Duration(milliseconds: 300));
Future<void> openDatabase() => Future.delayed(const Duration(milliseconds: 200));
Future<void> fetchMenu() => Future.delayed(const Duration(milliseconds: 400));

Future<void> startOneByOne() async {
  await readSettings();
  await openDatabase();
  await fetchMenu();
}

// {w_c_parallel}
Future<void> startTogether() => Future.wait([readSettings(), openDatabase(), fetchMenu()]).then((_) {});

// {w_c_first}
void main() {
  final ready = startTogether();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      {w_rtl}
      theme: ThemeData(colorSchemeSeed: Colors.brown),
      home: FutureBuilder(
        future: ready,
        builder: (context, snapshot) => snapshot.connectionState == ConnectionState.done ? const MenuPage() : const Splash(),
      ),
    ),
  );
}

class Splash extends StatelessWidget {
  const Splash({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(mainAxisSize: MainAxisSize.min, spacing: 16, children: [CircularProgressIndicator(), Text('{w_loading}')]),
    ),
  );
}
""",
    "test/startup_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/startup.dart';

Future<int> timed(Future<void> Function() start) async {
  final watch = Stopwatch()..start();
  await start();
  return watch.elapsedMilliseconds;
}

void main() {
  test('{w_t_startup}', () async {
    debugPrint('one by one: ${await timed(startOneByOne)} ms');
    debugPrint('together:   ${await timed(startTogether)} ms');
  });
}
""",
    # Projects
    "test/list_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/rows.dart';

var created = 0;

DrinkRow row(int n) {
  created++;
  return DrinkRow(n: n);
}

Future<void> measure(WidgetTester tester, String name, Widget Function() list) async {
  created = 0;
  rowBuilds = 0;
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: list())));
  debugPrint('${name.padRight(21)}$created rows created, $rowBuilds built');
}

void main() {
  testWidgets('{w_t_list}', (tester) async {
    await measure(tester, 'ListView(children:)', () => ListView(children: [for (var n = 1; n <= 1000; n++) row(n)]));
    await measure(tester, 'ListView.builder', () => ListView.builder(itemCount: 1000, itemBuilder: (context, i) => row(i + 1)));
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pump();
    debugPrint('after scrolling 3000 pixels: ${find.byType(DrinkRow).evaluate().length} rows alive, $created created in all');
    expect(created, lessThan(100));
  });
}
""",
    "test/isolate_test.dart": """import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

String bigJson() => jsonEncode([
  for (var i = 0; i < 200000; i++) {'id': i, 'drink': 'Latte $i', 'price': 45, 'extras': ['oat milk', 'vanilla']},
]);

int total(String json) => (jsonDecode(json) as List).fold(0, (sum, order) => sum + (order as Map)['price'] as int);

// A frame is due every 16 ms: count how many times the main isolate was free to draw one.
Future<(int, int, int)> whileWorking(FutureOr<int> Function() work) async {
  var frames = 0;
  final ticker = Timer.periodic(const Duration(milliseconds: 16), (_) => frames++);
  final watch = Stopwatch()..start();
  final result = await work();
  final ms = watch.elapsedMilliseconds;
  ticker.cancel();
  return (result, ms, frames);
}

void main() {
  test('{w_t_isolate}', () async {
    final json = bigJson();
    debugPrint('JSON: ${(json.length / 1024 / 1024).toStringAsFixed(1)} MB, 200000 orders');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final (a, msA, framesA) = await whileWorking(() => total(json));
    debugPrint('on the main isolate: $msA ms, ${msA ~/ 16} frames due, $framesA drawn');
    final (b, msB, framesB) = await whileWorking(() => Isolate.run(() => total(json)));
    debugPrint('with Isolate.run:    $msB ms, ${msB ~/ 16} frames due, $framesB drawn');
    expect(a, b);
  });
}
""",
    "lib/repaint.dart": """import 'package:material_ui/material_ui.dart';

var chartPaints = 0;

class SalesChart extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    chartPaints++;
    final paint = Paint()..color = Colors.brown;
    for (var i = 0; i < 24; i++) {
      final h = size.height * (0.2 + (i * 37 % 80) / 100);
      canvas.drawRect(Rect.fromLTWH(i * size.width / 24, size.height - h, size.width / 30, h), paint);
    }
  }

  @override
  bool shouldRepaint(SalesChart old) => false;
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key, required this.boundary});

  final bool boundary;

  @override
  Widget build(BuildContext context) {
    final chart = CustomPaint(size: const Size(300, 160), painter: SalesChart());
    return Scaffold(
      body: Column(
        children: [
          const LinearProgressIndicator(),
          // {w_c_boundary}
          if (boundary) RepaintBoundary(child: chart) else chart,
        ],
      ),
    );
  }
}
""",
    "test/repaint_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/repaint.dart';

Future<int> paintsIn60Frames(WidgetTester tester, {required bool boundary}) async {
  await tester.pumpWidget(MaterialApp(key: ValueKey(boundary), home: Dashboard(boundary: boundary)));
  chartPaints = 0;
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  return chartPaints;
}

void main() {
  testWidgets('{w_t_repaint}', (tester) async {
    final without = await paintsIn60Frames(tester, boundary: false);
    final withBoundary = await paintsIn60Frames(tester, boundary: true);
    debugPrint('chart painted in 60 frames: without a boundary $without, with one $withBoundary');
    expect(withBoundary, 0);
  });
}
""",
}

SHOTS = [
    ("menu.png", "lib/menu.dart", "wait=800"),
]

TESTS = [
    ("rebuilds-test.sh", "test/rebuilds_test.dart"),
    ("image-test.sh", "test/image_test.dart"),
    ("startup-test.sh", "test/startup_test.dart"),
    ("projects/list-test.sh", "test/list_test.dart"),
    ("projects/isolate-test.sh", "test/isolate_test.dart"),
    ("projects/repaint-test.sh", "test/repaint_test.dart"),
]


def photo():
    """A large "photo" of a latte, 4032 x 3024 like a phone camera's, drawn here so that the book owns it."""
    out = HERE / "assets" / "photos" / "latte.jpg"
    if out.exists():
        return
    out.parent.mkdir(parents=True, exist_ok=True)
    w, h = 4032, 3024
    img = Image.new("RGB", (w, h), (214, 190, 160))
    d = ImageDraw.Draw(img)
    for y in range(0, h, 8):
        t = y / h
        d.rectangle((0, y, w, y + 8), fill=(int(225 - 60 * t), int(200 - 70 * t), int(170 - 80 * t)))
    cx, cy = w // 2, h // 2
    d.ellipse((cx - 1300, cy - 1300, cx + 1300, cy + 1300), fill=(250, 246, 240))
    d.ellipse((cx - 1100, cy - 1100, cx + 1100, cy + 1100), fill=(150, 95, 55))
    d.ellipse((cx - 950, cy - 950, cx + 950, cy + 950), fill=(196, 140, 90))
    for k in range(6):
        r = 700 - k * 110
        d.ellipse((cx - r * 0.8, cy - r, cx + r * 0.8, cy + r * 0.9), outline=(245, 230, 210), width=60)
    img = img.filter(ImageFilter.GaussianBlur(6))
    img.save(out, quality=88)


def main():
    photo()
    flutter_gallery(HERE, T, FILES, SHOTS, TESTS, assets=HERE / "assets")


if __name__ == "__main__":
    main()
