"""Writes the examples of Book 5, chapter "Navigation", in English and Arabic, photographs them after real taps
(found by their labels, as a screen reader finds them), and runs their tests.
Run: python3 make.py   (needs Flutter 3.50.1, Node.js and Playwright's Chromium; downloads go_router once)
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
        w_latte_d="Espresso and steamed milk", w_tea_d="Black tea with fresh mint",
        w_juice_d="Freshly squeezed", w_cake_d="Sponge, jam and cream",
        w_c_push="push puts a new page on top; the bar gets a back button by itself.",
        w_c_route="MaterialPageRoute: the page, with the platform's own animation.",
        w_c_await="push returns a Future: the page's answer, when it closes.",
        w_c_pop="pop closes this page and gives the answer back.",
        w_c_null="null: the customer went back without adding anything.",
        w_added="Added", w_less="Fewer", w_more="More", w_add="Add", w_to_order="to order",
        w_add2="Add 2 to order",
        w_t_result="the drink page sends the quantity back to the menu",
        w_orders="Orders", w_order="Order", w_delete="Delete", w_cancel="Cancel",
        w_delete_q="Delete this order?", w_delete_body="This cannot be undone.",
        w_delete_tip="Delete order",
        w_c_dialog="showDialog is a route too: it waits for the answer, true or false.",
        w_drinks="Drinks", w_food="Food", w_offers="Offers",
        w_c_tabs="A TabBar and a TabBarView, kept in step by the controller.",
        w_cookie="Cookie", w_muffin="Muffin", w_offer1="Two lattes for 80", w_offer2="Free cookie on Fridays",
        w_account="Account", w_c_nav="The bar at the bottom chooses which page the body shows.",
        w_c_indexed="IndexedStack keeps every page alive, so each keeps its scroll and its state.",
        w_c_drawer="A drawer slides in from the start edge.",
        w_settings="Settings", w_help="Help", w_signin="Signed in as Sara",
        w_empty="No orders yet",
        w_c_routes="Every screen has an address, like a website.",
        w_c_param=":id is a parameter: /drinks/2 shows drink number 2.",
        w_c_go="go: change the address; the router shows the page for it.",
        w_c_notfound="An address that matches nothing gets this page.",
        w_not_found="Page not found", w_home="Back to the menu",
        # Projects
        w_about="About Bit Café", w_about_body="A small café on the Nile, open since 2020. We roast our own coffee and bake every morning.",
        w_t_about="the about page opens and closes",
        w_skip="Skip", w_next="Next", w_start="Start",
        w_p1="Order ahead", w_p1d="Choose your drink before you arrive.",
        w_p2="Skip the queue", w_p2d="Your cup is ready when you walk in.",
        w_p3="Collect points", w_p3d="Every tenth coffee is on us.",
        w_c_pageview="PageView: full pages, swiped sideways; the controller moves it by code.",
        w_c_replace="pushReplacement: the onboarding is gone; back does not return to it.",
        w_welcome="Welcome to Bit Café",
        w_t_notfound="an unknown drink shows the not-found page",
    ),
    "ar": dict(
        w_rtl="// من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.\n"
              "builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),\n",
        w_egp="جنيه", w_cafe="مقهى بِت", w_menu="القائمة",
        w_latte="لاتيه", w_tea="شاي بالنعناع", w_juice="عصير برتقال", w_cake="كيك الكرز",
        w_latte_d="إسبريسو وحليب مُبخَّر", w_tea_d="شاي أسود بنعناع طازج",
        w_juice_d="معصور طازجاً", w_cake_d="إسفنج ومربى وكريمة",
        w_c_push="push تضع صفحة جديدة في الأعلى؛ ويحصل الشريط على زر رجوع وحده.",
        w_c_route="MaterialPageRoute: الصفحة، بحركة الانتقال الخاصة بالمنصة.",
        w_c_await="push تُرجع Future: إجابة الصفحة، حين تُغلق.",
        w_c_pop="pop تغلق هذه الصفحة وتعيد الإجابة.",
        w_c_null="null: رجع الزبون دون أن يضيف شيئاً.",
        w_added="أُضيف", w_less="أقل", w_more="أكثر", w_add="أضف", w_to_order="إلى الطلب",
        w_add2="أضف 2 إلى الطلب",
        w_t_result="صفحة المشروب تعيد الكمية إلى القائمة",
        w_orders="الطلبات", w_order="طلب", w_delete="احذف", w_cancel="إلغاء",
        w_delete_q="أتحذف هذا الطلب؟", w_delete_body="لا يمكن التراجع عن هذا.",
        w_delete_tip="احذف الطلب",
        w_c_dialog="showDialog مسار أيضاً: ينتظر الإجابة، صحيح أو خطأ.",
        w_drinks="المشروبات", w_food="المأكولات", w_offers="العروض",
        w_c_tabs="TabBar وTabBarView، يبقيهما المتحكم متزامنين.",
        w_cookie="كوكيز", w_muffin="مافن", w_offer1="كوبا لاتيه بـ 80", w_offer2="كوكيز مجاناً يوم الجمعة",
        w_account="حسابي", w_c_nav="الشريط في الأسفل يختار الصفحة التي يعرضها المحتوى.",
        w_c_indexed="IndexedStack تُبقي كل الصفحات حية، فتحتفظ كل منها بتمريرها وحالتها.",
        w_c_drawer="القائمة الجانبية تنزلق من حافة البداية.",
        w_settings="الإعدادات", w_help="المساعدة", w_signin="مسجّل باسم سارة",
        w_empty="لا طلبات بعد",
        w_c_routes="لكل شاشة عنوان، كالموقع.",
        w_c_param=":id معامل: /drinks/2 تعرض المشروب رقم 2.",
        w_c_go="go: غيّر العنوان؛ ويعرض الموجّه صفحته.",
        w_c_notfound="العنوان الذي لا يطابق شيئاً يحصل على هذه الصفحة.",
        w_not_found="الصفحة غير موجودة", w_home="العودة إلى القائمة",
        w_about="عن مقهى بِت", w_about_body="مقهى صغير على النيل، مفتوح منذ 2020. نحمّص قهوتنا بأنفسنا ونخبز كل صباح.",
        w_t_about="صفحة «عن المقهى» تُفتح وتُغلق",
        w_skip="تخطَّ", w_next="التالي", w_start="ابدأ",
        w_p1="اطلب مسبقاً", w_p1d="اختر مشروبك قبل أن تصل.",
        w_p2="تجاوز الطابور", w_p2d="كوبك جاهز حين تدخل.",
        w_p3="اجمع النقاط", w_p3d="كل قهوة عاشرة على حسابنا.",
        w_c_pageview="PageView: صفحات كاملة تُسحب جانباً؛ والمتحكم يحركها بالكود.",
        w_c_replace="pushReplacement: تختفي صفحات التعريف؛ والرجوع لا يعود إليها.",
        w_welcome="أهلاً بك في مقهى بِت",
        w_t_notfound="المشروب غير المعروف يعرض صفحة «غير موجود»",
    ),
}

DRINKS = """
class Drink {
  const Drink(this.name, this.description, this.price, this.image);

  final String name;
  final String description;
  final int price;
  final String image;
}

const drinks = [
  Drink('{w_latte}', '{w_latte_d}', 45, 'assets/images/latte.png'),
  Drink('{w_tea}', '{w_tea_d}', 25, 'assets/images/tea.png'),
  Drink('{w_juice}', '{w_juice_d}', 40, 'assets/images/juice.png'),
  Drink('{w_cake}', '{w_cake_d}', 60, 'assets/images/cake.png'),
];
"""

FILES = {
    "lib/push.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const MenuPage()));
}
""" + DRINKS + """
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{w_menu}')),
      body: ListView(
        children: [
          for (final drink in drinks)
            ListTile(
              leading: CircleAvatar(backgroundImage: AssetImage(drink.image)),
              title: Text(drink.name),
              subtitle: Text('${drink.price} {w_egp}'),
              // {w_c_push}
              onTap: () => Navigator.push(
                context,
                // {w_c_route}
                MaterialPageRoute(builder: (context) => DrinkPage(drink: drink)),
              ),
            ),
        ],
      ),
    );
  }
}

class DrinkPage extends StatelessWidget {
  const DrinkPage({super.key, required this.drink});

  final Drink drink;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(drink.name)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(drink.image, height: 240, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(drink.name, style: Theme.of(context).textTheme.headlineMedium),
                Text(drink.description),
                Text('${drink.price} {w_egp}', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
""",
    "lib/result.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const MenuPage()));
}
""" + DRINKS + """
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  Future<void> open(BuildContext context, Drink drink) async {
    // {w_c_await}
    final count = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (context) => OrderPage(drink: drink)),
    );
    // {w_c_null}
    if (count == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('{w_added} $count × ${drink.name}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{w_menu}')),
      body: ListView(
        children: [
          for (final drink in drinks)
            ListTile(
              leading: CircleAvatar(backgroundImage: AssetImage(drink.image)),
              title: Text(drink.name),
              subtitle: Text('${drink.price} {w_egp}'),
              onTap: () => open(context, drink),
            ),
        ],
      ),
    );
  }
}

class OrderPage extends StatefulWidget {
  const OrderPage({super.key, required this.drink});

  final Drink drink;

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.drink.name)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(widget.drink.image, height: 240, fit: BoxFit.cover),
          Padding(padding: const EdgeInsets.all(16), child: Text(widget.drink.description)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton.outlined(
                tooltip: '{w_less}',
                onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('$quantity', style: const TextStyle(fontSize: 22)),
              ),
              IconButton.outlined(
                tooltip: '{w_more}',
                onPressed: () => setState(() => quantity++),
                icon: const Icon(Icons.add),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  // {w_c_pop}
                  onPressed: () => Navigator.pop(context, quantity),
                  child: Text('{w_add} $quantity {w_to_order}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
""",
    "test/result_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/result.dart';

void main() {
  testWidgets('{w_t_result}', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MenuPage()));

    await tester.tap(find.text('{w_latte}'));
    await tester.pumpAndSettle();
    expect(find.text('{w_latte_d}'), findsOneWidget);

    await tester.tap(find.byTooltip('{w_more}'));
    await tester.pump();
    await tester.tap(find.text('{w_add2}'));
    await tester.pumpAndSettle();

    expect(find.text('{w_latte_d}'), findsNothing);
    expect(find.text('{w_added} 2 × {w_latte}'), findsOneWidget);
  });
}
""",
    "lib/dialog.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const OrdersPage()));
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final orders = [101, 102, 103];

  Future<void> delete(int order) async {
    // {w_c_dialog}
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('{w_delete_q}'),
        content: const Text('{w_delete_body}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('{w_cancel}')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('{w_delete}')),
        ],
      ),
    );
    if (sure == true) setState(() => orders.remove(order));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{w_orders}')),
      body: ListView(
        children: [
          for (final order in orders)
            ListTile(
              title: Text('{w_order} $order'),
              trailing: IconButton(
                tooltip: '{w_delete_tip}',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => delete(order),
              ),
            ),
        ],
      ),
    );
  }
}
""",
    "lib/tabs.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const TabsPage()));
}

class TabsPage extends StatelessWidget {
  const TabsPage({super.key});

  Widget list(List<String> items) => ListView(children: [for (final i in items) ListTile(title: Text(i))]);

  @override
  Widget build(BuildContext context) {
    // {w_c_tabs}
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('{w_cafe}'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.local_cafe), text: '{w_drinks}'),
              Tab(icon: Icon(Icons.bakery_dining), text: '{w_food}'),
              Tab(icon: Icon(Icons.local_offer), text: '{w_offers}'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            list(['{w_latte}', '{w_tea}', '{w_juice}']),
            list(['{w_cake}', '{w_cookie}', '{w_muffin}']),
            list(['{w_offer1}', '{w_offer2}']),
          ],
        ),
      ),
    );
  }
}
""",
    "lib/shell.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const Shell()));
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int page = 0;

  static const titles = ['{w_menu}', '{w_orders}', '{w_account}'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titles[page])),
      // {w_c_drawer}
      drawer: Drawer(
        child: ListView(
          children: const [
            DrawerHeader(child: Align(alignment: AlignmentDirectional.bottomStart, child: Text('{w_signin}'))),
            ListTile(leading: Icon(Icons.settings), title: Text('{w_settings}')),
            ListTile(leading: Icon(Icons.help_outline), title: Text('{w_help}')),
          ],
        ),
      ),
      // {w_c_indexed}
      body: IndexedStack(
        index: page,
        children: const [
          Center(child: Icon(Icons.local_cafe, size: 96)),
          Center(child: Text('{w_empty}')),
          Center(child: Icon(Icons.person, size: 96)),
        ],
      ),
      // {w_c_nav}
      bottomNavigationBar: NavigationBar(
        selectedIndex: page,
        onDestinationSelected: (i) => setState(() => page = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.local_cafe), label: '{w_menu}'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: '{w_orders}'),
          NavigationDestination(icon: Icon(Icons.person), label: '{w_account}'),
        ],
      ),
    );
  }
}
""",
    "lib/router.dart": """import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp.router({w_rtl}debugShowCheckedModeBanner: false, routerConfig: router));
}
""" + DRINKS + """
// {w_c_routes}
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MenuPage(),
      routes: [
        // {w_c_param}
        GoRoute(
          path: 'drinks/:id',
          builder: (context, state) => DrinkPage(index: int.parse(state.pathParameters['id']!)),
        ),
      ],
    ),
  ],
);

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{w_menu}')),
      body: ListView(
        children: [
          for (var i = 0; i < drinks.length; i++)
            ListTile(
              title: Text(drinks[i].name),
              // {w_c_go}
              onTap: () => context.go('/drinks/$i'),
            ),
        ],
      ),
    );
  }
}

class DrinkPage extends StatelessWidget {
  const DrinkPage({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final drink = drinks[index];
    return Scaffold(
      appBar: AppBar(title: Text(drink.name)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(drink.image, height: 240, fit: BoxFit.cover),
          Padding(padding: const EdgeInsets.all(16), child: Text(drink.description)),
        ],
      ),
    );
  }
}
""",
    # Projects
    "projects/about.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const HomePage()));
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{w_cafe}')),
      body: Center(
        child: FilledButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutPage())),
          child: const Text('{w_about}'),
        ),
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{w_about}')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.local_cafe, size: 96, color: Colors.brown),
            SizedBox(height: 16),
            Text('{w_about_body}', style: TextStyle(fontSize: 18), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
""",
    "test/about_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_about.dart';

void main() {
  testWidgets('{w_t_about}', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.tap(find.text('{w_about}'));
    await tester.pumpAndSettle();
    expect(find.text('{w_about_body}'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('{w_about_body}'), findsNothing);
  });
}
""",
    "projects/onboarding.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const Onboarding()));
}

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final controller = PageController();
  int page = 0;

  static const pages = [
    (Icons.phone_iphone, '{w_p1}', '{w_p1d}'),
    (Icons.directions_walk, '{w_p2}', '{w_p2d}'),
    (Icons.card_giftcard, '{w_p3}', '{w_p3d}'),
  ];

  void finish() {
    // {w_c_replace}
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Scaffold(body: Center(child: Text('{w_welcome}')))),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = page == pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(onPressed: finish, child: const Text('{w_skip}')),
            ),
            // {w_c_pageview}
            Expanded(
              child: PageView(
                controller: controller,
                onPageChanged: (i) => setState(() => page = i),
                children: [
                  for (final (icon, title, text) in pages)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 12,
                        children: [
                          Icon(icon, size: 120, color: Colors.brown),
                          Text(title, style: Theme.of(context).textTheme.headlineMedium),
                          Text(text, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(4),
                    width: i == page ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == page ? Colors.brown : Colors.brown.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: last
                      ? finish
                      : () => controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                  child: Text(last ? '{w_start}' : '{w_next}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
""",
    "projects/routes.dart": """import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp.router({w_rtl}debugShowCheckedModeBanner: false, routerConfig: router()));
}

const names = ['{w_latte}', '{w_tea}', '{w_juice}', '{w_cake}'];

GoRouter router([String start = '/']) => GoRouter(
  initialLocation: start,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('{w_menu}')),
        body: ListView(
          children: [
            for (var i = 0; i < names.length; i++)
              ListTile(title: Text(names[i]), onTap: () => context.go('/drinks/$i')),
          ],
        ),
      ),
      routes: [
        GoRoute(
          path: 'drinks/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id']!);
            if (id == null || id < 0 || id >= names.length) {
              return const NotFoundPage();
            }
            return Scaffold(
              appBar: AppBar(title: Text(names[id])),
              body: Center(child: Text(names[id], style: const TextStyle(fontSize: 32))),
            );
          },
        ),
      ],
    ),
  ],
  // {w_c_notfound}
  errorBuilder: (context, state) => const NotFoundPage(),
);

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            const Icon(Icons.search_off, size: 96, color: Colors.grey),
            const Text('{w_not_found}', style: TextStyle(fontSize: 24)),
            FilledButton(onPressed: () => context.go('/'), child: const Text('{w_home}')),
          ],
        ),
      ),
    );
  }
}
""",
    "test/routes_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_routes.dart';

void main() {
  testWidgets('{w_t_notfound}', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router('/drinks/99')));
    await tester.pumpAndSettle();
    expect(find.text('{w_not_found}'), findsOneWidget);

    await tester.tap(find.text('{w_home}'));
    await tester.pumpAndSettle();
    expect(find.text('{w_latte}'), findsOneWidget);
  });
}
""",
}

SHOTS = [
    ("push-menu.png", "lib/push.dart", ""),
    ("push-drink.png", "lib/push.dart", "text={w_latte}"),
    ("result-order.png", "lib/result.dart", "text={w_latte}|button={w_more}"),
    ("result-back.png", "lib/result.dart", "text={w_latte}|button={w_more}|button={w_add2}"),
    ("dialog.png", "lib/dialog.dart", "button={w_delete_tip}"),
    ("tabs.png", "lib/tabs.dart", "tab={w_food}"),
    ("shell-orders.png", "lib/shell.dart", "tab={w_orders}"),
    ("shell-drawer.png", "lib/shell.dart", "button=Open navigation menu"),
    ("router.png", "lib/router.dart#/drinks/1", ""),
    ("about.png", "projects/about.dart", "button={w_about}"),
    ("onboarding.png", "projects/onboarding.dart", "button={w_next}"),
    ("not-found.png", "projects/routes.dart#/drinks/99", ""),
]

TESTS = [
    ("result-test.sh", "test/result_test.dart"),
    ("projects/about-test.sh", "test/about_test.dart"),
    ("projects/routes-test.sh", "test/routes_test.dart"),
]


def main():
    flutter_gallery(HERE, T, FILES, SHOTS, TESTS, assets=HERE.parent / "lists" / "assets", packages=["go_router"])


if __name__ == "__main__":
    main()
