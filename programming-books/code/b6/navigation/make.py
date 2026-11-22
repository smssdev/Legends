"""Writes the examples of Book 6, chapter "Navigation at Scale with go_router", in English and Arabic: a café
app with three tabs that keep their state, deep links, a sign-in redirect that returns where it was asked,
a not-found page, and their tests. Screenshots open the app at real addresses (#/orders/2).
Run: python3 make.py   (needs Flutter 3.50.1, Node.js and Playwright's Chromium)
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent.parent / "b5"))
from kit import flutter_gallery  # noqa: E402

T = {
    "en": dict(
        w_rtl="",
        w_menu="Menu", w_orders="Orders", w_account="Account", w_egp="EGP",
        w_latte="Latte", w_tea="Mint tea", w_cake="Cherry cake",
        w_order_n="Order", w_items="Items", w_no_drink="No drink called", w_no_order="No order number",
        w_signin="Sign in", w_signin_to="Sign in to continue to", w_signed_in="You are signed in.",
        w_signout="Sign out", w_not_found="Page not found", w_home="Back to the menu",
        w_c_auth="Who is signed in. The router listens to it, and redirects when it changes.",
        w_c_routes="Every address in one place: links build them here, and never by hand.",
        w_c_refresh="Run the redirect again whenever the auth changes.",
        w_c_redirect="Runs before every navigation. Return a new address to send the person elsewhere, or null.",
        w_c_from="Remember where the person wanted to go, and only ever return inside the app.",
        w_c_shell="Three tabs, each with its own stack of pages, kept alive when you switch.",
        w_c_nested="A child route: /menu/latte sits on top of /menu, so the back button returns to the menu.",
        w_c_outside="Outside the shell: sign-in covers the whole screen, without tabs.",
        w_c_error="Any address that matches no route.",
        w_c_bar="goBranch switches tab and keeps each tab's stack; tapping the current tab again goes to its first page.",
        w_c_go="go: change the address. The router builds the right stack for it.",
        w_t_redirect="sign-in is required for the account, and returns where it was asked",
        w_t_tabs="tabs keep their pages, and deep links have a way back",
        w_t_missing="unknown addresses and ids get a page that says so",
        # Projects
        w_t_routes="links are built in one place, and encoded correctly",
        w_max="Up to", w_any="Any price",
        w_c_query="The filter lives in the address: share it, bookmark it, press back.",
        w_t_query="the filter comes from the address",
        w_edit="Edit name", w_name="Name", w_leave="Leave without saving?", w_stay="Stay", w_discard="Discard",
        w_c_exit="Asked before leaving this route by any way: back button, tab, or go.",
        w_t_exit="unsaved changes are not lost by accident",
    ),
    "ar": dict(
        w_rtl="// من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.\n"
              "builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),\n",
        w_menu="القائمة", w_orders="الطلبات", w_account="الحساب", w_egp="جنيه",
        w_latte="لاتيه", w_tea="شاي بالنعناع", w_cake="كيك الكرز",
        w_order_n="الطلب", w_items="القطع", w_no_drink="لا مشروب باسم", w_no_order="لا طلب برقم",
        w_signin="سجّل الدخول", w_signin_to="سجّل الدخول لتتابع إلى", w_signed_in="أنت مسجّل الدخول.",
        w_signout="سجّل الخروج", w_not_found="الصفحة غير موجودة", w_home="عُد إلى القائمة",
        w_c_auth="من سجّل الدخول. والموجّه يستمع إليه، ويحوّل حين يتغير.",
        w_c_routes="كل العناوين في مكان واحد: الروابط تُبنى هنا، ولا تُكتب باليد أبداً.",
        w_c_refresh="أعد تشغيل التحويل كلما تغيّر تسجيل الدخول.",
        w_c_redirect="يعمل قبل كل انتقال. أعد عنواناً جديداً لترسل الشخص إلى مكان آخر، أو null.",
        w_c_from="تذكّر أين أراد الشخص أن يذهب، ولا تُرجع إلا إلى داخل التطبيق.",
        w_c_shell="ثلاثة ألسنة، لكل منها كومة صفحاته، تبقى حية حين تنتقل بينها.",
        w_c_nested="مسار ابن: /menu/latte فوق /menu، فيعود زر الرجوع إلى القائمة.",
        w_c_outside="خارج الإطار: تسجيل الدخول يغطي الشاشة كلها، بلا ألسنة.",
        w_c_error="أي عنوان لا يطابق مساراً.",
        w_c_bar="goBranch تنتقل بين الألسنة وتُبقي كومة كل لسان؛ ولمس اللسان الحالي من جديد يعود إلى صفحته الأولى.",
        w_c_go="go: غيّر العنوان. والموجّه يبني له الكومة الصحيحة.",
        w_t_redirect="الحساب يحتاج تسجيل الدخول، ويعود إلى حيث طُلب",
        w_t_tabs="الألسنة تحفظ صفحاتها، والروابط العميقة لها طريق رجوع",
        w_t_missing="العناوين والأرقام المجهولة تجد صفحة تقول ذلك",
        w_t_routes="الروابط تُبنى في مكان واحد، وتُرمَّز كما يجب",
        w_max="حتى", w_any="أي سعر",
        w_c_query="الفلتر يعيش في العنوان: شاركه، واحفظه، واضغط رجوع.",
        w_t_query="الفلتر يأتي من العنوان",
        w_edit="عدّل الاسم", w_name="الاسم", w_leave="تغادر دون حفظ؟", w_stay="ابقَ", w_discard="تجاهل",
        w_c_exit="يُسأل قبل مغادرة هذا المسار بأي طريقة: زر الرجوع، أو لسان، أو go.",
        w_t_exit="التغييرات غير المحفوظة لا تضيع خطأً",
    ),
}

FILES = {
    "lib/cafe/auth.dart": """import 'package:material_ui/material_ui.dart';

// {w_c_auth}
class Auth extends ChangeNotifier {
  var signedIn = false;

  void signIn() {
    signedIn = true;
    notifyListeners();
  }

  void signOut() {
    signedIn = false;
    notifyListeners();
  }
}
""",
    "lib/cafe/routes.dart": """// {w_c_routes}
abstract final class Routes {
  static const menu = '/menu';
  static const orders = '/orders';
  static const account = '/account';
  static const edit = '/account/edit';

  static String drink(String id) => '/menu/$id';
  static String order(int id) => '/orders/$id';
  static String menuUpTo(int max) => Uri(path: menu, queryParameters: {'max': '$max'}).toString();
  static String signIn({required String from}) => Uri(path: '/signin', queryParameters: {'from': from}).toString();
}
""",
    "lib/cafe/data.dart": """const drinks = {'latte': ('{w_latte}', 45), 'tea': ('{w_tea}', 25), 'cake': ('{w_cake}', 60)};
const orders = {1: 3, 2: 1, 3: 2};
""",
    "lib/cafe/router.dart": """import 'package:go_router/go_router.dart';

import 'auth.dart';
import 'pages.dart';
import 'routes.dart';

GoRouter buildRouter(Auth auth) => GoRouter(
  initialLocation: Routes.menu,
  // {w_c_refresh}
  refreshListenable: auth,
  // {w_c_redirect}
  redirect: (context, state) {
    final path = state.matchedLocation;
    if (!auth.signedIn && path.startsWith(Routes.account)) {
      return Routes.signIn(from: state.uri.toString());
    }
    if (auth.signedIn && path == '/signin') {
      // {w_c_from}
      final from = state.uri.queryParameters['from'] ?? Routes.menu;
      return from.startsWith('/') && !from.startsWith('//') ? from : Routes.menu;
    }
    return null;
  },
  // {w_c_error}
  errorBuilder: (context, state) => NotFoundPage(uri: state.uri),
  routes: [
    // {w_c_shell}
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => TabsScaffold(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.menu,
              builder: (context, state) => MenuPage(max: int.tryParse(state.uri.queryParameters['max'] ?? '')),
              routes: [
                // {w_c_nested}
                GoRoute(path: ':id', builder: (context, state) => DrinkPage(id: state.pathParameters['id']!)),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.orders,
              builder: (context, state) => const OrdersPage(),
              routes: [
                GoRoute(path: ':id', builder: (context, state) => OrderPage(id: int.tryParse(state.pathParameters['id']!))),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.account,
              builder: (context, state) => AccountPage(auth: auth),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) => const EditNamePage(),
                  // {w_c_exit}
                  onExit: (context, state) => EditNamePage.confirmLeave(context),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    // {w_c_outside}
    GoRoute(
      path: '/signin',
      builder: (context, state) => SignInPage(auth: auth, from: state.uri.queryParameters['from'] ?? Routes.menu),
    ),
  ],
);
""",
    "lib/cafe/pages.dart": """import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'auth.dart';
import 'data.dart';
import 'routes.dart';

class TabsScaffold extends StatelessWidget {
  const TabsScaffold({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        // {w_c_bar}
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.local_cafe), label: '{w_menu}'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: '{w_orders}'),
          NavigationDestination(icon: Icon(Icons.person), label: '{w_account}'),
        ],
      ),
    );
  }
}

class MenuPage extends StatelessWidget {
  const MenuPage({super.key, this.max});

  final int? max;

  @override
  Widget build(BuildContext context) {
    final shown = drinks.entries.where((e) => max == null || e.value.$2 <= max!);
    return Scaffold(
      appBar: AppBar(title: const Text('{w_menu}')),
      body: ListView(
        children: [
          // {w_c_query}
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: const Text('{w_any}'), selected: max == null, onSelected: (_) => context.go(Routes.menu)),
                for (final limit in [30, 50])
                  ChoiceChip(
                    label: Text('{w_max} $limit'),
                    selected: max == limit,
                    onSelected: (_) => context.go(Routes.menuUpTo(limit)),
                  ),
              ],
            ),
          ),
          for (final MapEntry(key: id, value: (name, price)) in shown)
            ListTile(
              title: Text(name),
              subtitle: Text('$price {w_egp}'),
              trailing: const Icon(Icons.chevron_right),
              // {w_c_go}
              onTap: () => context.go(Routes.drink(id)),
            ),
        ],
      ),
    );
  }
}

class DrinkPage extends StatelessWidget {
  const DrinkPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final drink = drinks[id];
    return Scaffold(
      appBar: AppBar(title: Text(drink?.$1 ?? id)),
      body: Center(
        child: drink == null
            ? Text('{w_no_drink} "$id"')
            : Text('${drink.$2} {w_egp}', style: Theme.of(context).textTheme.displaySmall),
      ),
    );
  }
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{w_orders}')),
      body: ListView(
        children: [
          for (final MapEntry(key: id, value: items) in orders.entries)
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text('{w_order_n} $id'),
              subtitle: Text('{w_items}: $items'),
              onTap: () => context.go(Routes.order(id)),
            ),
        ],
      ),
    );
  }
}

class OrderPage extends StatelessWidget {
  const OrderPage({super.key, required this.id});

  final int? id;

  @override
  Widget build(BuildContext context) {
    final items = orders[id];
    return Scaffold(
      appBar: AppBar(title: Text('{w_order_n} ${id ?? '?'}')),
      body: Center(
        child: Text(items == null ? '{w_no_order} ${id ?? '?'}' : '{w_items}: $items', style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key, required this.auth});

  final Auth auth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{w_account}')),
      body: ListView(
        children: [
          const ListTile(leading: Icon(Icons.verified_user), title: Text('{w_signed_in}')),
          ListTile(leading: const Icon(Icons.edit), title: const Text('{w_edit}'), onTap: () => context.go(Routes.edit)),
          ListTile(leading: const Icon(Icons.logout), title: const Text('{w_signout}'), onTap: auth.signOut),
        ],
      ),
    );
  }
}

class SignInPage extends StatelessWidget {
  const SignInPage({super.key, required this.auth, required this.from});

  final Auth auth;
  final String from;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            const Icon(Icons.lock_outline, size: 64),
            Text('{w_signin_to}'),
            Text(from, textDirection: TextDirection.ltr, style: Theme.of(context).textTheme.titleMedium),
            FilledButton(onPressed: auth.signIn, child: const Text('{w_signin}')),
          ],
        ),
      ),
    );
  }
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key, required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            const Icon(Icons.explore_off, size: 64),
            Text('{w_not_found}', style: Theme.of(context).textTheme.headlineSmall),
            Text('$uri', textDirection: TextDirection.ltr),
            FilledButton(onPressed: () => context.go(Routes.menu), child: const Text('{w_home}')),
          ],
        ),
      ),
    );
  }
}

class EditNamePage extends StatefulWidget {
  const EditNamePage({super.key});

  static var unsaved = false;

  static Future<bool> confirmLeave(BuildContext context) async {
    if (!unsaved) {
      return true;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('{w_leave}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('{w_stay}')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('{w_discard}')),
        ],
      ),
    );
    if (leave ?? false) {
      unsaved = false;
    }
    return leave ?? false;
  }

  @override
  State<EditNamePage> createState() => _EditNamePageState();
}

class _EditNamePageState extends State<EditNamePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{w_edit}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          decoration: const InputDecoration(labelText: '{w_name}'),
          onChanged: (_) => EditNamePage.unsaved = true,
        ),
      ),
    );
  }
}
""",
    "lib/cafe_app.dart": """import 'package:material_ui/material_ui.dart';

import 'cafe/auth.dart';
import 'cafe/router.dart';

void main() {
  final router = buildRouter(Auth());
  runApp(
    MaterialApp.router(
      debugShowCheckedModeBanner: false,
      {w_rtl}
      theme: ThemeData(colorSchemeSeed: Colors.brown),
      routerConfig: router,
    ),
  );
}
""",
    "test/helpers.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe/auth.dart';
import 'package:bit_app/cafe/router.dart';

Future<GoRouter> pumpCafe(WidgetTester tester, Auth auth) async {
  final router = buildRouter(auth);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return router;
}

String where(GoRouter router) => '${router.routerDelegate.currentConfiguration.uri}';
""",
    "test/redirect_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe/auth.dart';

import 'helpers.dart';

void main() {
  testWidgets('{w_t_redirect}', (tester) async {
    final auth = Auth();
    final router = await pumpCafe(tester, auth);

    router.go('/account');
    await tester.pumpAndSettle();
    debugPrint('signed out, asked /account: ${where(router)}');

    auth.signIn();
    await tester.pumpAndSettle();
    debugPrint('after signing in:           ${where(router)}');
    expect(where(router), '/account');

    auth.signOut();
    await tester.pumpAndSettle();
    debugPrint('after signing out:          ${where(router)}');

    router.go('/signin?from=https://evil.example');
    auth.signIn();
    await tester.pumpAndSettle();
    debugPrint('from an outside address:    ${where(router)}');
    expect(where(router), '/menu');
  });
}
""",
    "test/tabs_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe/auth.dart';

import 'helpers.dart';

void main() {
  testWidgets('{w_t_tabs}', (tester) async {
    final router = await pumpCafe(tester, Auth());
    await tester.tap(find.text('{w_cake}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('{w_orders}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('{w_menu}').last);
    await tester.pumpAndSettle();
    expect(where(router), '/menu/cake');

    // {w_c_deep}
    router.go('/orders/2');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(where(router), '/orders');
  });
}
""",
    "test/missing_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/cafe/auth.dart';

import 'helpers.dart';

void main() {
  testWidgets('{w_t_missing}', (tester) async {
    final router = await pumpCafe(tester, Auth());
    router.go('/nothing/here');
    await tester.pumpAndSettle();
    expect(find.text('{w_not_found}'), findsOneWidget);

    router.go('/orders/abc');
    await tester.pumpAndSettle();
    expect(find.text('{w_no_order} ?'), findsOneWidget);

    router.go('/menu/coffee');
    await tester.pumpAndSettle();
    expect(find.text('{w_no_drink} "coffee"'), findsOneWidget);
  });
}
""",
    # Projects
    "test/routes_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/cafe/routes.dart';

void main() {
  test('{w_t_routes}', () {
    expect(Routes.order(3), '/orders/3');
    expect(Routes.menuUpTo(40), '/menu?max=40');
    expect(Routes.signIn(from: '/account?tab=2'), '/signin?from=%2Faccount%3Ftab%3D2');
  });
}
""",
    "test/query_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe/auth.dart';
import 'package:bit_app/cafe/routes.dart';

import 'helpers.dart';

void main() {
  testWidgets('{w_t_query}', (tester) async {
    final router = await pumpCafe(tester, Auth());
    expect(find.text('{w_cake}'), findsOneWidget);

    router.go(Routes.menuUpTo(50));
    await tester.pumpAndSettle();
    expect(find.text('{w_cake}'), findsNothing);
    expect(find.text('{w_latte}'), findsOneWidget);

    await tester.tap(find.text('{w_max} 30'));
    await tester.pumpAndSettle();
    expect(where(router), '/menu?max=30');
    expect(find.byType(ListTile), findsOneWidget);
  });
}
""",
    "test/exit_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe/auth.dart';
import 'package:bit_app/cafe/pages.dart';

import 'helpers.dart';

void main() {
  testWidgets('{w_t_exit}', (tester) async {
    EditNamePage.unsaved = false;
    final router = await pumpCafe(tester, Auth()..signIn());
    router.go('/account/edit');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Sara');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('{w_leave}'), findsOneWidget);
    await tester.tap(find.text('{w_stay}'));
    await tester.pumpAndSettle();
    expect(where(router), '/account/edit');

    await tester.tap(find.text('{w_menu}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('{w_discard}'));
    await tester.pumpAndSettle();
    expect(where(router), '/menu');
  });
}
""",
}

SHOTS = [
    ("menu.png", "lib/cafe_app.dart#/menu", ""),
    ("deep.png", "lib/cafe_app.dart#/orders/2", ""),
    ("kept.png", "lib/cafe_app.dart#/menu", "text={w_cake}|wait=800|at={w_x2},745|wait=800|at={w_x1},745|wait=800"),
    ("signin.png", "lib/cafe_app.dart#/account", ""),
    ("notfound.png", "lib/cafe_app.dart#/nothing/here", ""),
    ("query.png", "lib/cafe_app.dart#/menu?max=50", ""),
]
T["en"].update(w_x1="65", w_x2="195", w_c_deep="A deep link straight to an order: the stack is built, so back returns to the list.")
T["ar"].update(w_x1="325", w_x2="195", w_c_deep="رابط عميق إلى طلب مباشرة: تُبنى الكومة، فيعود زر الرجوع إلى القائمة.")

TESTS = [
    ("redirect-test.sh", "test/redirect_test.dart"),
    ("tabs-test.sh", "test/tabs_test.dart"),
    ("missing-test.sh", "test/missing_test.dart"),
    ("projects/routes-test.sh", "test/routes_test.dart"),
    ("projects/query-test.sh", "test/query_test.dart"),
    ("projects/exit-test.sh", "test/exit_test.dart"),
]


def main():
    flutter_gallery(HERE, T, FILES, SHOTS, TESTS, packages=["go_router"])


if __name__ == "__main__":
    main()
