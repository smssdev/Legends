"""Writes the examples of Book 5, chapter "Layouts That Fit Every Screen", in English and Arabic, photographs
them on a phone and on a tablet, and runs their tests (one of which fails on purpose, to show an overflow).
Run: python3 make.py   (needs Flutter 3.50.1, Node.js and Playwright's Chromium; takes a few minutes)
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import flutter_gallery  # noqa: E402

T = {
    "en": dict(
        w_rtl="", w_comma=",",
        w_main="mainAxisAlignment", w_cross="crossAxisAlignment",
        w_c_box="A coloured square with a number: the same in every example.",
        w_c_rows="The same three boxes, arranged four ways.",
        w_c_expanded="Expanded takes the free space; flex shares it out.",
        w_c_flexible="Flexible: as wide as it needs, but no wider than the room left.",
        w_long="A very long name for a drink that does not fit on one line",
        w_t_overflow="a long name in a row", w_t_fixed="the same row, with Flexible",
        w_c_stack="Stack: children on top of each other; Positioned pins one to an edge.",
        w_new="NEW", w_special="Pistachio latte", w_special_price="55 EGP",
        w_c_badge="A badge on the corner of the cart icon.",
        w_c_wrap="Wrap: like a Row, but goes on to the next line when it is full.",
        w_tags="hot,iced,sweet,no sugar,oat milk,decaf,large,extra shot,to go",
        w_c_layoutbuilder="LayoutBuilder tells us how much room we have; we choose the layout.",
        w_c_narrow="Narrow: one column. Wide: side by side.",
        w_menu="Menu", w_order="Your order", w_menu_body="Latte, tea, cake…", w_order_body="2 × Latte",
        w_c_mq="MediaQuery: the size of the whole screen, and how it is held.",
        w_width="width", w_height="height", w_portrait="portrait", w_landscape="landscape",
        # The café dashboard
        w_cafe="Bit Café", w_today="Today", w_c_banner="The banner: a gradient, with the title pinned to its bottom.",
        w_orders="orders", w_sales="sales", w_rating="rating",
        w_c_stats="Three cards share the width equally.",
        w_c_columns="Two columns of sections on a wide screen, one on a phone.",
        w_popular="Most popular", w_latte="Latte", w_tea="Tea", w_cake="Cake",
        w_hours="Opening hours", w_hours_body="Every day, 8:00 to 22:00",
        # Projects
        w_cairo="Cairo", w_sunny="Sunny", w_feels="Feels like 29°",
        w_cart="Cart", w_add="Add a cup", w_items="items",
        w_t_badge="the badge counts the cups",
        w_drinks="Latte,Tea,Mocha,Juice,Water,Cocoa,Espresso,Smoothie",
    ),
    "ar": dict(
        w_comma="،",
        w_rtl="// من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.\n"
              "builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),\n",
        w_main="mainAxisAlignment", w_cross="crossAxisAlignment",
        w_c_box="مربع ملوّن برقم: هو نفسه في كل مثال.",
        w_c_rows="الصناديق الثلاثة نفسها، مرتبة بأربع طرق.",
        w_c_expanded="Expanded يأخذ المساحة الفارغة؛ وflex يقسمها.",
        w_c_flexible="Flexible: بالعرض الذي يحتاجه، لكن لا أعرض من المساحة الباقية.",
        w_long="اسم طويل جداً لمشروب لا يتسع له سطر واحد في الشاشة",
        w_t_overflow="اسم طويل في صف", w_t_fixed="الصف نفسه، مع Flexible",
        w_c_stack="Stack: أبناء بعضهم فوق بعض؛ وPositioned يثبّت أحدهم عند حافة.",
        w_new="جديد", w_special="لاتيه بالفستق", w_special_price="55 جنيهاً",
        w_c_badge="شارة على زاوية أيقونة السلة.",
        w_c_wrap="Wrap: مثل Row، لكنه ينتقل إلى السطر التالي حين يمتلئ.",
        w_tags="ساخن,مثلج,حلو,بلا سكر,حليب الشوفان,منزوع الكافيين,كبير,جرعة إضافية,سفري",
        w_c_layoutbuilder="LayoutBuilder يخبرنا كم مساحة لدينا؛ ونحن نختار التخطيط.",
        w_c_narrow="ضيق: عمود واحد. عريض: جنباً إلى جنب.",
        w_menu="القائمة", w_order="طلبك", w_menu_body="لاتيه، شاي، كيك…", w_order_body="2 × لاتيه",
        w_c_mq="MediaQuery: حجم الشاشة كلها، وكيف يُمسك الجهاز.",
        w_width="العرض", w_height="الارتفاع", w_portrait="عمودي", w_landscape="أفقي",
        w_cafe="مقهى بِت", w_today="اليوم", w_c_banner="اللافتة: تدرّج لوني، والعنوان مثبّت في أسفلها.",
        w_orders="طلب", w_sales="مبيعات", w_rating="تقييم",
        w_c_stats="ثلاث بطاقات تتقاسم العرض بالتساوي.",
        w_c_columns="عمودان من الأقسام على الشاشة العريضة، وعمود واحد على الجوال.",
        w_popular="الأكثر طلباً", w_latte="لاتيه", w_tea="شاي", w_cake="كيك",
        w_hours="مواعيد العمل", w_hours_body="كل يوم، من 8:00 إلى 22:00",
        w_cairo="القاهرة", w_sunny="مشمس", w_feels="الإحساس 29°",
        w_cart="السلة", w_add="أضف كوباً", w_items="قطع",
        w_t_badge="الشارة تعدّ الأكواب",
        w_drinks="لاتيه,شاي,موكا,عصير,مياه,كاكاو,إسبريسو,سموذي",
    ),
}

BOX = """
// {w_c_box}
class Box extends StatelessWidget {
  const Box(this.n, {super.key, this.size = 56});

  final int n;
  final double size;

  static const colors = [Colors.teal, Colors.orange, Colors.indigo];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: colors[(n - 1) % 3],
      child: Text('$n', style: const TextStyle(color: Colors.white, fontSize: 22)),
    );
  }
}
"""

FILES = {
    "lib/rows.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const RowsPage()));
}
""" + BOX + """
class Labelled extends StatelessWidget {
  const Labelled(this.label, this.child, {super.key});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
        Container(color: Colors.grey.shade200, height: 80, child: child),
        const SizedBox(height: 16),
      ],
    );
  }
}

class RowsPage extends StatelessWidget {
  const RowsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const boxes = [Box(1), Box(2), Box(3)];
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        // {w_c_rows}
        child: Column(
          children: [
            Labelled('start', Row(children: boxes)),
            Labelled('center', Row(mainAxisAlignment: MainAxisAlignment.center, children: boxes)),
            Labelled('spaceBetween', Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: boxes)),
            Labelled(
              'spaceEvenly + cross end',
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: boxes,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
""",
    "lib/expanded.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const ExpandedPage()));
}
""" + BOX + """
class ExpandedPage extends StatelessWidget {
  const ExpandedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 24,
          children: [
            // {w_c_expanded}
            const Row(children: [Box(1), Expanded(child: Box(2)), Box(3)]),
            const Row(
              children: [
                Expanded(child: Box(1)),
                Expanded(flex: 2, child: Box(2)),
                Expanded(child: Box(3)),
              ],
            ),
            // {w_c_flexible}
            Row(
              children: [
                const Icon(Icons.local_cafe, size: 32),
                const SizedBox(width: 8),
                const Flexible(child: Text('{w_long}', style: TextStyle(fontSize: 18))),
                const SizedBox(width: 8),
                Container(width: 48, height: 32, color: Colors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
""",
    "test/overflow_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('{w_t_overflow}', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 300,
          child: Row(
            children: [
              Icon(Icons.local_cafe),
              Text('{w_long}'),
            ],
          ),
        ),
      ),
    );
  });
}
""",
    "test/fixed_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('{w_t_fixed}', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 300,
          child: Row(
            children: [
              Icon(Icons.local_cafe),
              Flexible(child: Text('{w_long}')),
            ],
          ),
        ),
      ),
    );
  });
}
""",
    "lib/stack.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const StackPage()));
}

class StackPage extends StatelessWidget {
  const StackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 40,
          children: [
            // {w_c_stack}
            Stack(
              children: [
                Container(
                  width: 300,
                  height: 180,
                  decoration: BoxDecoration(color: Colors.brown.shade300, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.coffee, size: 96, color: Colors.white),
                ),
                PositionedDirectional(
                  top: 12,
                  start: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                    child: const Text('{w_new}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const PositionedDirectional(
                  bottom: 12,
                  start: 12,
                  end: 12,
                  child: Row(
                    children: [
                      Text('{w_special}', style: TextStyle(color: Colors.white, fontSize: 20)),
                      Spacer(),
                      Text('{w_special_price}', style: TextStyle(color: Colors.white, fontSize: 18)),
                    ],
                  ),
                ),
              ],
            ),
            // {w_c_badge}
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart, size: 56),
                Positioned(
                  top: -6,
                  right: -6,
                  child: CircleAvatar(
                    radius: 13,
                    backgroundColor: Colors.red,
                    child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
""",
    "lib/wrap.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const WrapPage()));
}

class WrapPage extends StatelessWidget {
  const WrapPage({super.key});

  @override
  Widget build(BuildContext context) {
    const tags = '{w_tags}';
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
        // {w_c_wrap}
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final tag in tags.split(',')) Chip(label: Text(tag))],
        ),
      ),
    );
  }
}
""",
    "lib/responsive.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const ResponsivePage()));
}

class Panel extends StatelessWidget {
  const Panel(this.title, this.body, this.color, {super.key});

  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(body),
        ],
      ),
    );
  }
}

class ResponsivePage extends StatelessWidget {
  const ResponsivePage({super.key});

  @override
  Widget build(BuildContext context) {
    // {w_c_mq}
    final size = MediaQuery.sizeOf(context);
    final held = size.width > size.height ? '{w_landscape}' : '{w_portrait}';
    final menu = Panel('{w_menu}', '{w_menu_body}', Colors.teal.shade100);
    final order = Panel('{w_order}', '{w_order_body}', Colors.orange.shade100);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('{w_width} ${size.width.round()}{w_comma} {w_height} ${size.height.round()}{w_comma} $held'),
            const SizedBox(height: 16),
            // {w_c_layoutbuilder}
            LayoutBuilder(
              builder: (context, constraints) {
                // {w_c_narrow}
                if (constraints.maxWidth < 600) {
                  return Column(spacing: 16, crossAxisAlignment: CrossAxisAlignment.stretch, children: [menu, order]);
                }
                return Row(
                  spacing: 16,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: menu),
                    Expanded(child: order),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
""",
    "lib/dashboard.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const Dashboard()));
}

class Stat extends StatelessWidget {
  const Stat(this.value, this.label, this.icon, {super.key});

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: Colors.brown),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class Section extends StatelessWidget {
  const Section(this.title, this.lines, {super.key});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            for (final line in lines) Text(line),
          ],
        ),
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    const popular = Section('{w_popular}', ['1. {w_latte}', '2. {w_tea}', '3. {w_cake}']);
    const hours = Section('{w_hours}', ['{w_hours_body}']);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // {w_c_banner}
          Container(
            height: 140,
            padding: const EdgeInsets.all(20),
            alignment: AlignmentDirectional.bottomStart,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Colors.brown, Colors.orange]),
            ),
            child: const Text('{w_cafe} · {w_today}', style: TextStyle(color: Colors.white, fontSize: 28)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              spacing: 12,
              children: [
                // {w_c_stats}
                const Row(
                  children: [
                    Expanded(child: Stat('48', '{w_orders}', Icons.receipt_long)),
                    Expanded(child: Stat('2,160', '{w_sales}', Icons.payments)),
                    Expanded(child: Stat('4.8', '{w_rating}', Icons.star)),
                  ],
                ),
                // {w_c_columns}
                LayoutBuilder(
                  builder: (context, constraints) => constraints.maxWidth < 600
                      ? const Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [popular, hours])
                      : const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: popular),
                            Expanded(child: hours),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
""",
    # Projects
    "projects/weather.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const WeatherPage()));
}

class WeatherPage extends StatelessWidget {
  const WeatherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.wb_sunny, size: 56, color: Colors.orange),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('{w_cairo}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('{w_sunny}'),
                      Text('{w_feels}', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                Text('31°', style: Theme.of(context).textTheme.displaySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
""",
    "projects/cart_badge.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const CartPage()));
}

class CartBadge extends StatelessWidget {
  const CartBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.shopping_cart, size: 32),
        if (count > 0)
          PositionedDirectional(
            top: -8,
            end: -10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
              child: Text(count > 9 ? '9+' : '$count', style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
      ],
    );
  }
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  int cups = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('{w_cart}'),
        actions: [
          Padding(padding: const EdgeInsets.all(16), child: CartBadge(count: cups)),
        ],
      ),
      body: Center(
        child: FilledButton.icon(
          onPressed: () => setState(() => cups++),
          icon: const Icon(Icons.add),
          label: const Text('{w_add}'),
        ),
      ),
    );
  }
}
""",
    "test/badge_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_cart_badge.dart';

void main() {
  testWidgets('{w_t_badge}', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CartPage()));
    expect(find.text('0'), findsNothing);
    for (var i = 1; i <= 10; i++) {
      await tester.tap(find.text('{w_add}'));
      await tester.pump();
    }
    expect(find.text('9+'), findsOneWidget);
  });
}
""",
    "projects/grid.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const GridPage()));
}

class GridPage extends StatelessWidget {
  const GridPage({super.key});

  @override
  Widget build(BuildContext context) {
    const drinks = '{w_drinks}';
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const gap = 12.0;
            final columns = (constraints.maxWidth / 180).floor().clamp(2, 6);
            final tile = (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final name in drinks.split(','))
                  Container(
                    width: tile,
                    height: tile * 0.75,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.brown.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [const Icon(Icons.local_cafe, size: 36), Text(name)],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
""",
}

SHOTS = [
    ("rows.png", "lib/rows.dart", ""),
    ("expanded.png", "lib/expanded.dart", ""),
    ("stack.png", "lib/stack.dart", ""),
    ("wrap.png", "lib/wrap.dart", ""),
    ("responsive-phone.png", "lib/responsive.dart", ""),
    ("responsive-tablet.png", "lib/responsive.dart", "", "820x540"),
    ("dashboard-phone.png", "lib/dashboard.dart", ""),
    ("dashboard-tablet.png", "lib/dashboard.dart", "", "820x540"),
    ("weather.png", "projects/weather.dart", ""),
    ("cart.png", "projects/cart_badge.dart", "195,418 195,418 195,418"),
    ("grid-phone.png", "projects/grid.dart", ""),
    ("grid-tablet.png", "projects/grid.dart", "", "820x540"),
]


def overflow(lines):
    """The overflow report is long: keep its first lines, and the summary."""
    keep, skipping = [], False
    for line in lines:
        if "The overflowing RenderFlex" in line or "The relevant error-causing widget" in line:
            skipping = True
        if line.startswith("═") and skipping:
            skipping = False
            keep.append("…")
        if not skipping:
            keep.append(line)
    return keep


TESTS = [
    ("overflow-test.sh", "test/overflow_test.dart", overflow),
    ("fixed-test.sh", "test/fixed_test.dart"),
    ("projects/badge-test.sh", "test/badge_test.dart"),
]


def main():
    flutter_gallery(HERE, T, FILES, SHOTS, TESTS)


if __name__ == "__main__":
    main()
