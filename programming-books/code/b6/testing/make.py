"""Writes the examples of Book 6, chapter "Testing: Unit, Widget, Golden and Integration", in English and
Arabic: unit tests for prices, an API client tested with a fake HTTP client, a screen tested with a fake
repository, golden images (and one that fails on purpose), coverage, and an integration test that runs the
real app as a Linux desktop program on a virtual screen.
Run: python3 make.py   (needs Flutter 3.50.1 with the Linux desktop tools, Xvfb, Node.js and Chromium)
"""
import os
import subprocess
import sys
from pathlib import Path

from PIL import Image

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent.parent / "b5"))
from kit import WORK, flutter_gallery  # noqa: E402

T = {
    "en": dict(
        w_rtl="",
        w_menu="Menu", w_latte="Latte", w_tea="Mint tea", w_cake="Cherry cake", w_egp="EGP", w_total="Total",
        w_happy="Happy hour: 20% off", w_failed="The menu could not be loaded.", w_retry="Try again",
        w_c_happy="Happy hour: 20% off between 15:00 and 17:00 (17:00 itself is not included).",
        w_c_port="The screen needs a menu, not HTTP: any class with this method will do.",
        w_c_status="Anything but 200 is a failure the screen can show.",
        w_c_now="The clock is a parameter, so a test can choose the time.",
        w_c_demo="For the demo app: the first visit fails, the second works, as on a bad connection.",
        w_c_fake="A fake: real behaviour, no network. The test decides when the menu arrives.",
        w_c_mock="A fake HTTP client from package:http: it answers like a server, and checks the request.",
        w_c_fixed="10:00 on a weekday: no happy hour, so the total is predictable.",
        w_c_brand="A teammate changes the brand colour, and forgets the tiles.",
        w_t_total="the total of an order", w_t_happy_total="happy hour takes 20% off",
        w_t_empty="an empty order costs nothing",
        w_t_parse="reads the menu from the server", w_t_500="a server error becomes a MenuException",
        w_t_loading="shows a spinner, then the menu", w_t_add="tapping a drink adds it to the total",
        w_t_golden="a drink tile looks as approved", w_t_golden_rtl="a drink tile in Arabic and in dark mode",
        w_t_flow="from a failed start to an order", w_t_retry="Try again asks the repository again",
        w_t_edges="happy hour at its edges",
    ),
    "ar": dict(
        w_rtl="// من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.\n"
              "builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),\n",
        w_menu="القائمة", w_latte="لاتيه", w_tea="شاي بالنعناع", w_cake="كيك الكرز", w_egp="جنيه", w_total="المجموع",
        w_happy="ساعة السعادة: خصم 20%", w_failed="تعذّر تحميل القائمة.", w_retry="حاول مرة أخرى",
        w_c_happy="ساعة السعادة: خصم 20% بين 15:00 و17:00 (والساعة 17:00 نفسها خارجها).",
        w_c_port="الشاشة تحتاج قائمة، لا HTTP: أي صنف فيه هذه الدالة يكفي.",
        w_c_status="أي شيء غير 200 فشل تستطيع الشاشة عرضه.",
        w_c_now="الساعة معامل، فيستطيع الاختبار أن يختار الوقت.",
        w_c_demo="لتطبيق العرض: الزيارة الأولى تفشل والثانية تنجح، كما على اتصال سيئ.",
        w_c_fake="بديل مزيّف: سلوك حقيقي بلا شبكة. والاختبار يقرر متى تصل القائمة.",
        w_c_mock="عميل HTTP مزيّف من package:http: يرد كما يرد الخادم، ويفحص الطلب.",
        w_c_fixed="العاشرة صباحاً في يوم عمل: لا ساعة سعادة، فالمجموع معروف مسبقاً.",
        w_c_brand="زميل يغيّر لون العلامة، وينسى البلاطات.",
        w_t_total="مجموع طلب", w_t_happy_total="ساعة السعادة تخصم 20%",
        w_t_empty="الطلب الفارغ لا يكلّف شيئاً",
        w_t_parse="يقرأ القائمة من الخادم", w_t_500="خطأ الخادم يصير MenuException",
        w_t_loading="يعرض مؤشراً ثم القائمة", w_t_add="الضغط على مشروب يضيفه إلى المجموع",
        w_t_golden="بلاطة المشروب كما اعتُمدت", w_t_golden_rtl="بلاطة المشروب بالعربية وفي الوضع الداكن",
        w_t_flow="من بداية فاشلة إلى طلب", w_t_retry="«حاول مرة أخرى» تسأل المستودع من جديد",
        w_t_edges="ساعة السعادة عند حدودها",
    ),
}

FILES = {
    "lib/domain/pricing.dart": """class Line {
  const Line(this.name, this.price, this.quantity);

  final String name;
  final int price;
  final int quantity;
}

// {w_c_happy}
bool isHappyHour(DateTime time) => time.hour >= 15 && time.hour < 17;

int total(List<Line> lines, DateTime at) {
  final subtotal = lines.fold(0, (sum, line) => sum + line.price * line.quantity);
  return isHappyHour(at) ? subtotal - subtotal * 20 ~/ 100 : subtotal;
}
""",
    "lib/data/menu.dart": """import 'dart:convert';

import 'package:http/http.dart' as http;

class Drink {
  const Drink(this.id, this.name, this.price);

  factory Drink.fromJson(Map<String, dynamic> json) => Drink(json['id'] as String, json['name'] as String, json['price'] as int);

  final String id;
  final String name;
  final int price;
}

class MenuException implements Exception {
  const MenuException(this.reason);

  final String reason;

  @override
  String toString() => 'MenuException: $reason';
}

// {w_c_port}
abstract interface class MenuRepository {
  Future<List<Drink>> menu();
}

class MenuApi implements MenuRepository {
  MenuApi(this.client, {this.base = 'https://api.bitcafe.online'});

  final http.Client client;
  final String base;

  @override
  Future<List<Drink>> menu() async {
    final response = await client.get(Uri.parse('$base/menu'));
    // {w_c_status}
    if (response.statusCode != 200) {
      throw MenuException('status ${response.statusCode}');
    }
    final items = jsonDecode(response.body) as List<dynamic>;
    return [for (final item in items) Drink.fromJson(item as Map<String, dynamic>)];
  }
}
""",
    "lib/data/demo_menu.dart": """import 'menu.dart';

// {w_c_demo}
class DemoMenu implements MenuRepository {
  var calls = 0;

  @override
  Future<List<Drink>> menu() async {
    calls++;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (calls == 1) {
      throw const MenuException('timeout');
    }
    return const [Drink('latte', '{w_latte}', 45), Drink('tea', '{w_tea}', 30), Drink('cake', '{w_cake}', 55)];
  }
}
""",
    "lib/ui/menu_screen.dart": """import 'package:material_ui/material_ui.dart';

import '../data/menu.dart';
import '../domain/pricing.dart';

class MenuScreen extends StatefulWidget {
  // {w_c_now}
  const MenuScreen({super.key, required this.repository, this.now = DateTime.now});

  final MenuRepository repository;
  final DateTime Function() now;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late Future<List<Drink>> drinks = widget.repository.menu();
  final order = <String, int>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{w_menu}')),
      body: FutureBuilder(
        future: drinks,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 16,
                children: [
                  const Text('{w_failed}'),
                  FilledButton(
                    onPressed: () => setState(() {
                      drinks = widget.repository.menu();
                    }),
                    child: const Text('{w_retry}'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final menu = snapshot.data!;
          final lines = [
            for (final drink in menu)
              if (order[drink.id] case final quantity?) Line(drink.name, drink.price, quantity),
          ];
          final at = widget.now();
          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    for (final drink in menu)
                      DrinkTile(
                        drink: drink,
                        quantity: order[drink.id] ?? 0,
                        onAdd: () => setState(() => order[drink.id] = (order[drink.id] ?? 0) + 1),
                      ),
                  ],
                ),
              ),
              ListTile(
                title: Text('{w_total}: ${total(lines, at)} {w_egp}', style: Theme.of(context).textTheme.titleLarge),
                subtitle: isHappyHour(at) ? const Text('{w_happy}') : null,
              ),
            ],
          );
        },
      ),
    );
  }
}

class DrinkTile extends StatelessWidget {
  const DrinkTile({super.key, required this.drink, required this.quantity, required this.onAdd});

  final Drink drink;
  final int quantity;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
        child: Text('$quantity'),
      ),
      title: Text(drink.name),
      subtitle: Text('${drink.price} {w_egp}'),
      trailing: Icon(Icons.add_circle, color: colors.primary),
      onTap: onAdd,
    );
  }
}
""",
    "lib/cafe_app.dart": """import 'package:material_ui/material_ui.dart';

import 'data/demo_menu.dart';
import 'data/menu.dart';
import 'ui/menu_screen.dart';

class BitApp extends StatelessWidget {
  const BitApp({super.key, required this.repository, this.now = DateTime.now});

  final MenuRepository repository;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      {w_rtl}
      theme: ThemeData(colorSchemeSeed: Colors.brown),
      home: MenuScreen(repository: repository, now: now),
    );
  }
}

void main() => runApp(BitApp(repository: DemoMenu()));
""",
    "test/pricing_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/domain/pricing.dart';

void main() {
  final morning = DateTime(2026, 11, 23, 10);
  final afternoon = DateTime(2026, 11, 23, 15, 30);
  const order = [Line('latte', 45, 2), Line('cake', 55, 1)];

  test('{w_t_total}', () {
    expect(total(order, morning), 145);
  });

  test('{w_t_happy_total}', () {
    expect(total(order, afternoon), 116);
  });

  test('{w_t_empty}', () {
    expect(total(const [], afternoon), 0);
  });
}
""",
    "test/menu_api_test.dart": """import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bit_app/data/menu.dart';

void main() {
  test('{w_t_parse}', () async {
    // {w_c_mock}
    final client = MockClient((request) async {
      expect(request.url.toString(), 'https://api.bitcafe.online/menu');
      return http.Response(jsonEncode([{'id': 'latte', 'name': 'Latte', 'price': 45}]), 200);
    });
    final menu = await MenuApi(client).menu();
    expect(menu.single.name, 'Latte');
    expect(menu.single.price, 45);
  });

  test('{w_t_500}', () async {
    final client = MockClient((request) async => http.Response('oops', 500));
    expect(MenuApi(client).menu(), throwsA(isA<MenuException>().having((e) => e.reason, 'reason', 'status 500')));
  });
}
""",
    "test/menu_screen_test.dart": """import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/data/menu.dart';
import 'package:bit_app/ui/menu_screen.dart';

// {w_c_fake}
class FakeMenu implements MenuRepository {
  final arrives = Completer<List<Drink>>();

  @override
  Future<List<Drink>> menu() => arrives.future;
}

const drinks = [Drink('latte', 'Latte', 45), Drink('cake', 'Cherry cake', 55)];

Widget screen(MenuRepository repository) => MaterialApp(
  // {w_c_fixed}
  home: MenuScreen(repository: repository, now: () => DateTime(2026, 11, 23, 10)),
);

void main() {
  testWidgets('{w_t_loading}', (tester) async {
    final fake = FakeMenu();
    await tester.pumpWidget(screen(fake));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    fake.arrives.complete(drinks);
    await tester.pump();
    expect(find.text('Latte'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('{w_t_add}', (tester) async {
    final fake = FakeMenu()..arrives.complete(drinks);
    await tester.pumpWidget(screen(fake));
    await tester.pump();
    await tester.tap(find.text('Latte'));
    await tester.tap(find.text('Latte'));
    await tester.tap(find.text('Cherry cake'));
    await tester.pump();
    expect(find.textContaining(': 145 '), findsOneWidget);
  });
}
""",
    "test/golden_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/data/menu.dart';
import 'package:bit_app/ui/menu_screen.dart';

Widget tile(ThemeData theme) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: theme,
  home: const Scaffold(
    body: Center(
      child: SizedBox(
        width: 320,
        child: DrinkTile(drink: Drink('latte', 'Latte', 45), quantity: 2, onAdd: _nothing),
      ),
    ),
  ),
);

void _nothing() {}

void main() {
  testWidgets('{w_t_golden}', (tester) async {
    tester.view.physicalSize = const Size(320, 120);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(tile(ThemeData(colorSchemeSeed: Colors.brown)));
    await expectLater(find.byType(DrinkTile), matchesGoldenFile('goldens/drink_tile.png'));
  });
}
""",
    "test/golden_change_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/ui/menu_screen.dart';

import 'golden_test.dart' show tile;

void main() {
  testWidgets('{w_t_golden}', (tester) async {
    tester.view.physicalSize = const Size(320, 120);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // {w_c_brand}
    await tester.pumpWidget(tile(ThemeData(colorSchemeSeed: Colors.teal)));
    await expectLater(find.byType(DrinkTile), matchesGoldenFile('goldens/drink_tile.png'));
  });
}
""",
    "root/integration_test/order_flow_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:bit_app/cafe_app.dart';
import 'package:bit_app/data/demo_menu.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('{w_t_flow}', (tester) async {
    await tester.pumpWidget(BitApp(repository: DemoMenu(), now: () => DateTime(2026, 11, 23, 10)));
    await tester.pumpAndSettle();
    expect(find.text('{w_failed}'), findsOneWidget);

    await tester.tap(find.text('{w_retry}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('{w_latte}'));
    await tester.tap(find.text('{w_latte}'));
    await tester.tap(find.text('{w_cake}'));
    await tester.pumpAndSettle();
    expect(find.text('{w_total}: 145 {w_egp}'), findsOneWidget);
  });
}
""",
    "root/tool/coverage.dart": """import 'dart:io';

// Reads coverage/lcov.info, which `flutter test --coverage` writes, and prints the lines tested per file.
void main() {
  final hits = <String, (int, int)>{};
  String? file;
  for (final line in File('coverage/lcov.info').readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      file = line.substring(3);
    } else if (line.startsWith('DA:') && file != null) {
      final count = int.parse(line.split(',')[1]);
      final (hit, found) = hits[file] ?? (0, 0);
      hits[file] = (hit + (count > 0 ? 1 : 0), found + 1);
    }
  }
  var allHit = 0;
  var allFound = 0;
  for (final MapEntry(key: name, value: (hit, found)) in hits.entries) {
    stdout.writeln('${name.padRight(28)}${'$hit/$found'.padLeft(8)}  ${(100 * hit / found).toStringAsFixed(0).padLeft(3)}%');
    allHit += hit;
    allFound += found;
  }
  stdout.writeln('${'all'.padRight(28)}${'$allHit/$allFound'.padLeft(8)}  ${(100 * allHit / allFound).toStringAsFixed(0).padLeft(3)}%');
}
""",
    # Projects
    "test/edges_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/domain/pricing.dart';

void main() {
  group('{w_t_edges}', () {
    final cases = {
      DateTime(2026, 11, 23, 14, 59): false,
      DateTime(2026, 11, 23, 15): true,
      DateTime(2026, 11, 23, 16, 59, 59): true,
      DateTime(2026, 11, 23, 17): false,
      DateTime(2026, 11, 23, 3, 30): false,
    };
    cases.forEach((time, expected) {
      final hhmm = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      test('$hhmm is ${expected ? '' : 'not '}happy hour', () => expect(isHappyHour(time), expected));
    });
  });
}
""",
    "test/retry_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/data/menu.dart';
import 'package:bit_app/ui/menu_screen.dart';

class FlakyMenu implements MenuRepository {
  var calls = 0;

  @override
  Future<List<Drink>> menu() async {
    calls++;
    if (calls == 1) {
      throw const MenuException('timeout');
    }
    return const [Drink('latte', 'Latte', 45)];
  }
}

void main() {
  testWidgets('{w_t_retry}', (tester) async {
    final flaky = FlakyMenu();
    await tester.pumpWidget(MaterialApp(home: MenuScreen(repository: flaky)));
    await tester.pump();
    expect(find.text('{w_failed}'), findsOneWidget);
    expect(flaky.calls, 1);

    await tester.tap(find.text('{w_retry}'));
    await tester.pumpAndSettle();
    expect(flaky.calls, 2);
    expect(find.text('Latte'), findsOneWidget);
  });
}
""",
    "test/golden_rtl_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/data/menu.dart';
import 'package:bit_app/ui/menu_screen.dart';

void main() {
  testWidgets('{w_t_golden_rtl}', (tester) async {
    tester.view.physicalSize = const Size(320, 120);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.brown, brightness: Brightness.dark),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: DrinkTile(drink: Drink('latte', 'لاتيه', 45), quantity: 2, onAdd: _nothing),
              ),
            ),
          ),
        ),
      ),
    );
    await expectLater(find.byType(DrinkTile), matchesGoldenFile('goldens/drink_tile_rtl_dark.png'));
  });
}

void _nothing() {}
""",
}

SHOTS = [
    ("error.png", "lib/cafe_app.dart", "wait=800"),
    ("menu.png", "lib/cafe_app.dart", "button={w_retry}|wait=900|at=200,88|at=200,88|at=200,216"),
]


def golden_failure(lines):
    """The failing golden prints a long stack; the book keeps what it says about the pixels."""
    keep = [l for l in lines if not l.startswith("#") and (l.startswith("$") or "Golden" in l or "%" in l
            or "failures" in l or "Some tests failed" in l or "[E]" in l)]
    return keep


TESTS = [
    ("pricing-test.sh", "test/pricing_test.dart"),
    ("api-test.sh", "test/menu_api_test.dart"),
    ("screen-test.sh", "test/menu_screen_test.dart"),
    ("golden-test.sh", "test/golden_test.dart"),
    ("golden-fail.sh", "test/golden_change_test.dart", golden_failure),
    ("integration-test.sh", "integration_test/order_flow_test.dart -d linux"),
    ("projects/edges-test.sh", "test/edges_test.dart"),
    ("projects/retry-test.sh", "test/retry_test.dart"),
    ("projects/golden-rtl-test.sh", "test/golden_rtl_test.dart"),
]

SETUP = [
    ("golden-update.sh", "flutter test --update-goldens test/golden_test.dart test/golden_rtl_test.dart"),
    ("coverage-run.sh", "flutter test --coverage test/pricing_test.dart test/menu_api_test.dart test/menu_screen_test.dart"),
    ("coverage.sh", "dart run tool/coverage.dart"),
]


def goldens():
    """The approved images, and what the failing test found, side by side and at twice the size, for the book."""
    for lang in T:
        project = WORK / HERE.name / lang / "bit_app" / "test"
        shots = HERE / lang / "shots"
        approved = Image.open(project / "goldens" / "drink_tile.png").convert("RGB")
        new = Image.open(project / "failures" / "drink_tile_testImage.png").convert("RGB")
        diff = Image.open(project / "failures" / "drink_tile_isolatedDiff.png").convert("RGB")
        w, h = approved.size
        gap = 12
        row = Image.new("RGB", (w * 3 + gap * 2, h), (200, 200, 200))
        for k, image in enumerate((approved, new, diff)):
            row.paste(image, (k * (w + gap), 0))
        row.resize((row.width * 2, h * 2), Image.NEAREST).save(shots / "golden-compare.png")
        rtl = Image.open(project / "goldens" / "drink_tile_rtl_dark.png").convert("RGB")
        rtl.resize((w * 2, h * 2), Image.NEAREST).save(shots / "golden-rtl-dark.png")


def main():
    # A virtual screen for the integration test, which runs the app as a Linux desktop program.
    screen = subprocess.Popen(["Xvfb", ":94", "-screen", "0", "1280x800x24", "-ac"], stdout=subprocess.DEVNULL,
                              stderr=subprocess.DEVNULL)
    os.environ["DISPLAY"] = ":94"
    try:
        flutter_gallery(HERE, T, FILES, SHOTS, TESTS, setup=SETUP,
                        packages=["http", "'dev:integration_test:{\"sdk\":\"flutter\"}'"])
        goldens()
    finally:
        screen.terminate()


if __name__ == "__main__":
    main()
