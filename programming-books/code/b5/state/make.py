"""Writes the examples of Book 5, chapter "State with setState and Provider", in English and Arabic,
photographs them after real taps, and runs their tests.
Run: python3 make.py   (needs Flutter 3.50.1, Node.js and Playwright's Chromium; downloads provider once)
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import flutter_gallery  # noqa: E402

T = {
    "en": dict(
        w_rtl="", w_egp="EGP", w_cafe="Bit Café", w_menu="Menu",
        w_latte="Latte", w_tea="Mint tea", w_juice="Orange juice", w_cake="Cherry cake",
        w_add="Add", w_remove="Remove", w_basket="Basket", w_items="items", w_empty="Your basket is empty",
        w_total="Total", w_checkout="Check out",
        w_c_lift="The basket lives in the parent; both children get it, and a way to change it.",
        w_c_callback="The list does not own the basket: it calls back up.",
        w_c_notifier="A ChangeNotifier: the data, the rules, and a way to tell listeners it changed.",
        w_c_notify="Every change ends with notifyListeners().",
        w_c_view="Read-only views: the outside can look, not touch.",
        w_c_listenable="ListenableBuilder rebuilds its builder whenever the basket notifies.",
        w_c_provide="Provide one basket above the whole app.",
        w_c_watch="watch: read the basket, and rebuild when it changes.",
        w_c_read="read: use the basket once, without listening (in callbacks).",
        w_c_select="select: rebuild only when this one number changes.",
        w_t_model="the basket adds, counts and totals",
        w_t_app="adding on the menu shows up in the basket page",
        # Projects
        w_count="Cups today", w_reset="Reset", w_more="One more",
        w_favs="Favourites", w_all="All drinks", w_no_favs="Tap a heart to keep a drink here",
        w_like="Like", w_unlike="Unlike",
        w_t_favs="a heart on one tab shows on the other",
        w_settings="Settings", w_dark="Dark mode", w_big="Large text",
        w_t_settings="the setting changes the whole app",
        w_sample="Bit Café is open every day from 8:00 to 22:00.",
    ),
    "ar": dict(
        w_rtl="// من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.\n"
              "builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),\n",
        w_egp="جنيه", w_cafe="مقهى بِت", w_menu="القائمة",
        w_latte="لاتيه", w_tea="شاي بالنعناع", w_juice="عصير برتقال", w_cake="كيك الكرز",
        w_add="أضف", w_remove="احذف", w_basket="السلة", w_items="قطع", w_empty="سلتك فارغة",
        w_total="الإجمالي", w_checkout="إتمام الطلب",
        w_c_lift="السلة تعيش في الأب؛ وكل من الابنين يأخذها، ويأخذ طريقة لتغييرها.",
        w_c_callback="القائمة لا تملك السلة: إنها تستدعي من فوقها.",
        w_c_notifier="ChangeNotifier: البيانات، والقواعد، وطريقة لإخبار المستمعين بأنها تغيّرت.",
        w_c_notify="كل تغيير ينتهي بـ notifyListeners().",
        w_c_view="نوافذ للقراءة فقط: يستطيع الخارج أن ينظر، لا أن يلمس.",
        w_c_listenable="ListenableBuilder يعيد بناء دالته كلما أبلغت السلة.",
        w_c_provide="قدّم سلة واحدة فوق التطبيق كله.",
        w_c_watch="watch: اقرأ السلة، وأعد البناء حين تتغير.",
        w_c_read="read: استخدم السلة مرة، دون استماع (في الدوال المستدعاة).",
        w_c_select="select: أعد البناء فقط حين يتغير هذا الرقم وحده.",
        w_t_model="السلة تضيف وتعدّ وتجمع",
        w_t_app="الإضافة في القائمة تظهر في صفحة السلة",
        w_count="أكواب اليوم", w_reset="صفّر", w_more="كوب آخر",
        w_favs="المفضلة", w_all="كل المشروبات", w_no_favs="اضغط قلباً لتحفظ مشروباً هنا",
        w_like="أعجبني", w_unlike="ألغِ الإعجاب",
        w_t_favs="القلب في تبويب يظهر في الآخر",
        w_settings="الإعدادات", w_dark="الوضع الداكن", w_big="نص كبير",
        w_t_settings="الإعداد يغيّر التطبيق كله",
        w_sample="مقهى بِت مفتوح كل يوم من 8:00 إلى 22:00.",
    ),
}

DRINKS = """
class Drink {
  const Drink(this.name, this.price);

  final String name;
  final int price;
}

const drinks = [
  Drink('{w_latte}', 45),
  Drink('{w_tea}', 25),
  Drink('{w_juice}', 40),
  Drink('{w_cake}', 60),
];
"""

FILES = {
    "lib/lift.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const CafePage()));
}
""" + DRINKS + """
class CafePage extends StatefulWidget {
  const CafePage({super.key});

  @override
  State<CafePage> createState() => _CafePageState();
}

class _CafePageState extends State<CafePage> {
  // {w_c_lift}
  final basket = <Drink>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{w_menu}')),
      body: DrinkList(onAdd: (drink) => setState(() => basket.add(drink))),
      bottomNavigationBar: BasketBar(basket: basket),
    );
  }
}

class DrinkList extends StatelessWidget {
  const DrinkList({super.key, required this.onAdd});

  // {w_c_callback}
  final ValueChanged<Drink> onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final drink in drinks)
          ListTile(
            title: Text(drink.name),
            subtitle: Text('${drink.price} {w_egp}'),
            trailing: IconButton(
              tooltip: '{w_add} ${drink.name}',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => onAdd(drink),
            ),
          ),
      ],
    );
  }
}

class BasketBar extends StatelessWidget {
  const BasketBar({super.key, required this.basket});

  final List<Drink> basket;

  @override
  Widget build(BuildContext context) {
    final total = basket.fold(0, (sum, d) => sum + d.price);
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.all(20),
      child: Text(
        '${basket.length} {w_items} · {w_total} $total {w_egp}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
""",
    "lib/basket.dart": """// {w_c_notifier}
import 'package:material_ui/material_ui.dart';

class Basket extends ChangeNotifier {
  final Map<String, int> _counts = {};
  final Map<String, int> _prices = {};

  // {w_c_view}
  Map<String, int> get counts => Map.unmodifiable(_counts);
  int get count => _counts.values.fold(0, (a, b) => a + b);
  int get total => _counts.entries.fold(0, (sum, e) => sum + e.value * _prices[e.key]!);

  void add(String name, int price) {
    _counts.update(name, (n) => n + 1, ifAbsent: () => 1);
    _prices[name] = price;
    // {w_c_notify}
    notifyListeners();
  }

  void remove(String name) {
    final n = _counts[name];
    if (n == null) return;
    if (n == 1) {
      _counts.remove(name);
    } else {
      _counts[name] = n - 1;
    }
    notifyListeners();
  }
}
""",
    "test/basket_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/basket.dart';

void main() {
  test('{w_t_model}', () {
    final basket = Basket();
    var told = 0;
    basket.addListener(() => told++);

    basket.add('{w_latte}', 45);
    basket.add('{w_latte}', 45);
    basket.add('{w_cake}', 60);
    expect(basket.count, 3);
    expect(basket.total, 150);
    expect(basket.counts['{w_latte}'], 2);

    basket.remove('{w_latte}');
    expect(basket.total, 105);
    expect(told, 4);
  });
}
""",
    "lib/listenable.dart": """import 'package:material_ui/material_ui.dart';

import 'basket.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: CafePage(basket: Basket())));
}
""" + DRINKS + """
class CafePage extends StatelessWidget {
  const CafePage({super.key, required this.basket});

  final Basket basket;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{w_menu}')),
      body: ListView(
        children: [
          for (final drink in drinks)
            ListTile(
              title: Text(drink.name),
              subtitle: Text('${drink.price} {w_egp}'),
              trailing: IconButton(
                tooltip: '{w_add} ${drink.name}',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => basket.add(drink.name, drink.price),
              ),
            ),
        ],
      ),
      // {w_c_listenable}
      bottomNavigationBar: ListenableBuilder(
        listenable: basket,
        builder: (context, child) => Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          padding: const EdgeInsets.all(20),
          child: Text('${basket.count} {w_items} · {w_total} ${basket.total} {w_egp}'),
        ),
      ),
    );
  }
}
""",
    "lib/provided.dart": """import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'basket.dart';

void main() {
  runApp(
    // {w_c_provide}
    ChangeNotifierProvider(
      create: (context) => Basket(),
      child: MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const MenuPage()),
    ),
  );
}
""" + DRINKS + """
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('{w_menu}'),
        actions: const [BasketButton()],
      ),
      body: ListView(
        children: [
          for (final drink in drinks)
            ListTile(
              title: Text(drink.name),
              subtitle: Text('${drink.price} {w_egp}'),
              trailing: IconButton(
                tooltip: '{w_add} ${drink.name}',
                icon: const Icon(Icons.add_circle_outline),
                // {w_c_read}
                onPressed: () => context.read<Basket>().add(drink.name, drink.price),
              ),
            ),
        ],
      ),
    );
  }
}

class BasketButton extends StatelessWidget {
  const BasketButton({super.key});

  @override
  Widget build(BuildContext context) {
    // {w_c_select}
    final count = context.select<Basket, int>((b) => b.count);
    return IconButton(
      tooltip: '{w_basket}',
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BasketPage())),
      icon: Badge(isLabelVisible: count > 0, label: Text('$count'), child: const Icon(Icons.shopping_bag)),
    );
  }
}

class BasketPage extends StatelessWidget {
  const BasketPage({super.key});

  @override
  Widget build(BuildContext context) {
    // {w_c_watch}
    final basket = context.watch<Basket>();
    return Scaffold(
      appBar: AppBar(title: const Text('{w_basket}')),
      body: basket.count == 0
          ? const Center(child: Text('{w_empty}'))
          : ListView(
              children: [
                for (final MapEntry(key: name, value: n) in basket.counts.entries)
                  ListTile(
                    title: Text('$n × $name'),
                    trailing: IconButton(
                      tooltip: '{w_remove} $name',
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => basket.remove(name),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: basket.count == 0 ? null : () {},
          child: Text('{w_checkout} · ${basket.total} {w_egp}'),
        ),
      ),
    );
  }
}
""",
    "test/provided_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:bit_app/basket.dart';
import 'package:bit_app/provided.dart';

void main() {
  testWidgets('{w_t_app}', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(create: (context) => Basket(), child: const MaterialApp(home: MenuPage())),
    );
    await tester.tap(find.byTooltip('{w_add} {w_latte}'));
    await tester.tap(find.byTooltip('{w_add} {w_latte}'));
    await tester.tap(find.byTooltip('{w_add} {w_cake}'));
    await tester.pump();
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.byTooltip('{w_basket}'));
    await tester.pumpAndSettle();
    expect(find.text('2 × {w_latte}'), findsOneWidget);
    expect(find.text('{w_checkout} · 150 {w_egp}'), findsOneWidget);
  });
}
""",
    # Projects
    "projects/counter.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: CounterPage(counter: Counter())));
}

class Counter extends ChangeNotifier {
  int _value = 0;
  int get value => _value;

  void increment() {
    _value++;
    notifyListeners();
  }

  void reset() {
    _value = 0;
    notifyListeners();
  }
}

class CounterPage extends StatelessWidget {
  const CounterPage({super.key, required this.counter});

  final Counter counter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('{w_count}'),
        actions: [IconButton(tooltip: '{w_reset}', onPressed: counter.reset, icon: const Icon(Icons.refresh))],
      ),
      body: Center(
        child: ListenableBuilder(
          listenable: counter,
          builder: (context, child) => Text('${counter.value}', style: Theme.of(context).textTheme.displayLarge),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: counter.increment,
        icon: const Icon(Icons.local_cafe),
        label: const Text('{w_more}'),
      ),
    );
  }
}
""",
    "projects/favourites.dart": """import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => Favourites(),
      child: MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const Shell()),
    ),
  );
}

const names = ['{w_latte}', '{w_tea}', '{w_juice}', '{w_cake}'];

class Favourites extends ChangeNotifier {
  final Set<String> _names = {};
  Set<String> get names => Set.unmodifiable(_names);
  bool contains(String name) => _names.contains(name);

  void toggle(String name) {
    _names.contains(name) ? _names.remove(name) : _names.add(name);
    notifyListeners();
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final favs = context.watch<Favourites>();
    final shown = tab == 0 ? names : [for (final n in names) if (favs.contains(n)) n];
    return Scaffold(
      appBar: AppBar(title: Text(tab == 0 ? '{w_all}' : '{w_favs}')),
      body: shown.isEmpty
          ? const Center(child: Text('{w_no_favs}'))
          : ListView(
              children: [
                for (final name in shown)
                  ListTile(
                    title: Text(name),
                    trailing: IconButton(
                      tooltip: favs.contains(name) ? '{w_unlike} $name' : '{w_like} $name',
                      icon: Icon(favs.contains(name) ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                      onPressed: () => context.read<Favourites>().toggle(name),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.local_cafe), label: '{w_all}'),
          NavigationDestination(
            icon: Badge(isLabelVisible: favs.names.isNotEmpty, label: Text('${favs.names.length}'), child: const Icon(Icons.favorite)),
            label: '{w_favs}',
          ),
        ],
      ),
    );
  }
}
""",
    "test/favourites_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:bit_app/projects_favourites.dart';

void main() {
  testWidgets('{w_t_favs}', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(create: (context) => Favourites(), child: const MaterialApp(home: Shell())),
    );
    await tester.tap(find.byTooltip('{w_like} {w_tea}'));
    await tester.pump();
    await tester.tap(find.text('{w_favs}'));
    await tester.pump();
    expect(find.text('{w_tea}'), findsOneWidget);
    expect(find.text('{w_latte}'), findsNothing);
  });
}
""",
    "projects/settings.dart": """import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(ChangeNotifierProvider(create: (context) => Settings(), child: const SettingsApp()));
}

class Settings extends ChangeNotifier {
  bool _dark = false;
  bool _big = false;
  bool get dark => _dark;
  bool get big => _big;

  set dark(bool value) {
    _dark = value;
    notifyListeners();
  }

  set big(bool value) {
    _big = value;
    notifyListeners();
  }
}

class SettingsApp extends StatelessWidget {
  const SettingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();
    return MaterialApp(
      {w_rtl}debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      darkTheme: ThemeData(colorSchemeSeed: Colors.teal, brightness: Brightness.dark),
      themeMode: settings.dark ? ThemeMode.dark : ThemeMode.light,
      home: MediaQuery.withClampedTextScaling(
        minScaleFactor: settings.big ? 1.3 : 1,
        maxScaleFactor: settings.big ? 1.3 : 1,
        child: const SettingsPage(),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();
    return Scaffold(
      appBar: AppBar(title: const Text('{w_settings}')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('{w_dark}'),
            value: settings.dark,
            onChanged: (v) => context.read<Settings>().dark = v,
          ),
          SwitchListTile(
            title: const Text('{w_big}'),
            value: settings.big,
            onChanged: (v) => context.read<Settings>().big = v,
          ),
          const Padding(padding: EdgeInsets.all(16), child: Text('{w_sample}')),
        ],
      ),
    );
  }
}
""",
    "test/settings_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:bit_app/projects_settings.dart';

void main() {
  testWidgets('{w_t_settings}', (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider(create: (context) => Settings(), child: const SettingsApp()));
    final app = find.byType(MaterialApp);
    expect(tester.widget<MaterialApp>(app).themeMode, ThemeMode.light);

    await tester.tap(find.text('{w_dark}'));
    await tester.pumpAndSettle();
    expect(tester.widget<MaterialApp>(app).themeMode, ThemeMode.dark);
  });
}
""",
}

SHOTS = [
    ("lift.png", "lib/lift.dart", "button={w_add} {w_latte}|button={w_add} {w_latte}|button={w_add} {w_cake}"),
    ("listenable.png", "lib/listenable.dart", "button={w_add} {w_tea}|button={w_add} {w_juice}"),
    ("provided-menu.png", "lib/provided.dart", "button={w_add} {w_latte}|button={w_add} {w_latte}|button={w_add} {w_cake}"),
    ("provided-basket.png", "lib/provided.dart",
     "button={w_add} {w_latte}|button={w_add} {w_latte}|button={w_add} {w_cake}|button={w_basket}"),
    ("counter.png", "projects/counter.dart", "button={w_more}|button={w_more}|button={w_more}"),
    ("favourites.png", "projects/favourites.dart", "button={w_like} {w_tea}|button={w_like} {w_cake}|tab={w_favs}"),
    ("settings.png", "projects/settings.dart", "switch={w_dark}|switch={w_big}"),
]

TESTS = [
    ("basket-test.sh", "test/basket_test.dart"),
    ("provided-test.sh", "test/provided_test.dart"),
    ("projects/favourites-test.sh", "test/favourites_test.dart"),
    ("projects/settings-test.sh", "test/settings_test.dart"),
]


def main():
    flutter_gallery(HERE, T, FILES, SHOTS, TESTS, packages=["provider"])


if __name__ == "__main__":
    main()
