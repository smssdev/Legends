"""Writes the examples of Book 6, chapter "Capstone: A Production App", in English and Arabic: Bit Café, one
app that uses the whole book. Features in folders (Chapter 2), Riverpod (3), go_router (4), a repository
with an offline cache (5 and 6), design tokens (7), motion that respects reduced motion (8), lists that build
lazily (9), unit, widget and integration tests (10), accessibility checks and the Arabic locale (11),
configuration per environment (15) and crash reporting (16). Its full test suite runs, its main journey runs
as a real Linux app, and its screens are screenshots of the real web build.
Run: python3 make.py   (needs Flutter 3.50.1 with the Linux desktop tools, Xvfb, Node.js and Playwright's
Chromium)
"""
import os
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent.parent / "b5"))
from kit import WORK, Session, flutter_gallery  # noqa: E402

T = {
    "en": dict(
        w_locale="",
        w_title="Bit Café", w_menu="Menu", w_cart="Your order", w_add="Add", w_remove="Remove", w_items="items",
        w_egp="EGP", w_total="Total", w_place="Place order", w_empty="Nothing in your order yet.",
        w_order="Order", w_received="Received", w_preparing="Being prepared", w_ready="Ready at the counter",
        w_offline="Showing the saved menu. Pull to try again.", w_failed="The menu could not be loaded.",
        w_retry="Try again", w_open_cart="Open your order", w_fav="Save", w_unfav="Unsave",
        w_latte="Latte", w_latte_d="Espresso and steamed milk", w_tea="Mint tea", w_tea_d="Fresh mint, lightly sweet",
        w_cake="Cherry cake", w_cake_d="Baked this morning", w_juice="Orange juice", w_juice_d="Squeezed to order",
        w_queued="Saved. It will be sent when you are back online.",
        w_c_features="Each feature in its own folder: its pages, and nothing else's.",
        w_c_api="The app depends on this; the demo, the tests and the real server each provide one.",
        w_c_cache="The saved menu first, at once; then the fresh one, when it arrives.",
        w_c_cart="The cart is plain state: a map from drink to count, and its total.",
        w_c_tokens="Spaces and corners from Chapter 7: screens never choose numbers.",
        w_c_motion="The badge moves only if the person allows motion (Chapter 8).",
        w_c_lazy="Only the rows on screen are built (Chapter 9).",
        w_c_router="Three pages, and a route that a notification can open (Chapter 12).",
        w_c_main="Everything starts here: reporting first, then the app with its real dependencies.",
        w_c_outbox="When the network fails, the order waits in the outbox and is sent later (Chapter 6).",
        w_c_icon="Inside a ListTile, the tile's icon colour wins over the button's: say it explicitly.",
        w_t_cart="the cart adds, removes and totals", w_t_cache="the saved menu first, then the fresh one",
        w_t_journey="from the menu to an order that is ready", w_t_a11y="the main screens meet the accessibility guidelines",
        w_t_fav="favorites are remembered", w_t_robust="every screen, dark and at 200% text, without overflow",
        w_t_outbox="an order placed offline is sent when the network returns",
    ),
    "ar": dict(
        w_locale="  locale: const Locale('ar'),\n  supportedLocales: const [Locale('ar')],\n"
                 "  localizationsDelegates: GlobalMaterialLocalizations.delegates,\n",
        w_title="بت كافيه", w_menu="القائمة", w_cart="طلبك", w_add="أضف", w_remove="احذف", w_items="قطع",
        w_egp="جنيه", w_total="المجموع", w_place="أرسل الطلب", w_empty="لا شيء في طلبك بعد.",
        w_order="الطلب", w_received="وصل", w_preparing="قيد التحضير", w_ready="جاهز عند المنضدة",
        w_offline="نعرض القائمة المحفوظة. اسحب لتحاول مرة أخرى.", w_failed="تعذّر تحميل القائمة.",
        w_retry="حاول مرة أخرى", w_open_cart="افتح طلبك", w_fav="احفظ", w_unfav="ألغِ الحفظ",
        w_latte="لاتيه", w_latte_d="إسبريسو وحليب مبخّر", w_tea="شاي بالنعناع", w_tea_d="نعناع طازج، محلّى قليلاً",
        w_cake="كيك الكرز", w_cake_d="مخبوز هذا الصباح", w_juice="عصير برتقال", w_juice_d="يُعصر عند الطلب",
        w_queued="حُفظ. سيُرسل حين يعود الاتصال.",
        w_c_features="كل ميزة في مجلدها: صفحاتها، ولا شيء من غيرها.",
        w_c_api="التطبيق يعتمد على هذه؛ ويقدّم كلٌّ من العرض والاختبارات والخادم الحقيقي واحدة.",
        w_c_cache="القائمة المحفوظة أولاً، فوراً؛ ثم الجديدة حين تصل.",
        w_c_cart="السلة حالة بسيطة: خريطة من المشروب إلى العدد، ومجموعها.",
        w_c_tokens="المسافات والزوايا من الفصل 7: الشاشات لا تختار أرقاماً.",
        w_c_motion="الشارة تتحرك فقط إن سمح الشخص بالحركة (الفصل 8).",
        w_c_lazy="لا يُبنى إلا ما على الشاشة من صفوف (الفصل 9).",
        w_c_router="ثلاث صفحات، ومسار يستطيع الإشعار فتحه (الفصل 12).",
        w_c_main="كل شيء يبدأ هنا: البلاغات أولاً، ثم التطبيق باعتماداته الحقيقية.",
        w_c_outbox="حين تفشل الشبكة ينتظر الطلب في صندوق الصادر ويُرسل لاحقاً (الفصل 6).",
        w_c_icon="داخل ListTile يغلب لون أيقونة البلاطة لون الزر: قله صراحة.",
        w_t_cart="السلة تضيف وتحذف وتجمع", w_t_cache="القائمة المحفوظة أولاً، ثم الجديدة",
        w_t_journey="من القائمة إلى طلب جاهز", w_t_a11y="الشاشات الرئيسية تحقق إرشادات الإتاحة",
        w_t_fav="المفضلات تُتذكَّر", w_t_robust="كل شاشة، داكنة وبنص 200%، بلا فيض",
        w_t_outbox="طلب أُرسل دون اتصال يُرسل حين تعود الشبكة",
    ),
}

FILES = {
    "lib/config.dart": """abstract final class AppConfig {
  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8080');
}
""",
    "lib/design/tokens.dart": """// {w_c_tokens}
abstract final class Space {
  static const s = 8.0;
  static const m = 16.0;
  static const l = 24.0;
}

abstract final class Corner {
  static const m = 16.0;
}
""",
    "lib/data/models.dart": """class Drink {
  const Drink(this.id, this.name, this.about, this.price);

  factory Drink.fromJson(Map<String, Object?> json) =>
      Drink(json['id']! as String, json['name']! as String, json['about']! as String, json['price']! as int);

  final String id;
  final String name;
  final String about;
  final int price;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'about': about, 'price': price};
}

enum OrderStatus { received, preparing, ready }

class Order {
  const Order(this.id, this.status);

  final String id;
  final OrderStatus status;
}
""",
    "lib/data/cafe_api.dart": """import 'models.dart';

// {w_c_api}
abstract interface class CafeApi {
  Future<List<Drink>> menu();
  Future<Order> place(Map<String, int> lines);
  Future<Order> order(String id);
}

class DemoApi implements CafeApi {
  final _placed = <String, DateTime>{};

  @override
  Future<List<Drink>> menu() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const [
      Drink('latte', '{w_latte}', '{w_latte_d}', 45),
      Drink('tea', '{w_tea}', '{w_tea_d}', 30),
      Drink('cake', '{w_cake}', '{w_cake_d}', 55),
      Drink('juice', '{w_juice}', '{w_juice_d}', 40),
    ];
  }

  @override
  Future<Order> place(Map<String, int> lines) async {
    final id = '${41 + _placed.length}';
    _placed[id] = DateTime.now();
    return Order(id, OrderStatus.received);
  }

  @override
  Future<Order> order(String id) async {
    final seconds = DateTime.now().difference(_placed[id] ?? DateTime.now()).inSeconds;
    return Order(id, seconds < 2 ? OrderStatus.preparing : OrderStatus.ready);
  }
}
""",
    "lib/data/menu_repository.dart": """import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'cafe_api.dart';
import 'models.dart';

class MenuRepository {
  MenuRepository(this.api, this.prefs);

  final CafeApi api;
  final SharedPreferencesAsync prefs;

  // {w_c_cache}
  Stream<(List<Drink>, {bool fresh})> watch() async* {
    final saved = await prefs.getString('menu');
    if (saved != null) {
      yield ([for (final item in jsonDecode(saved) as List) Drink.fromJson(item as Map<String, Object?>)], fresh: false);
    }
    final menu = await api.menu();
    await prefs.setString('menu', jsonEncode([for (final drink in menu) drink.toJson()]));
    yield (menu, fresh: true);
  }
}
""",
    "lib/state/providers.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/cafe_api.dart';
import '../data/menu_repository.dart';
import '../data/models.dart';

final apiProvider = Provider<CafeApi>((ref) => DemoApi());
final prefsProvider = Provider<SharedPreferencesAsync>((ref) => SharedPreferencesAsync());

final menuProvider = StreamProvider<(List<Drink>, {bool fresh})>(
  (ref) => MenuRepository(ref.watch(apiProvider), ref.watch(prefsProvider)).watch(),
);

// {w_c_cart}
class Cart extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => {};

  void add(String id) => state = {...state, id: (state[id] ?? 0) + 1};

  void remove(String id) {
    final count = (state[id] ?? 0) - 1;
    state = {
      for (final MapEntry(:key, :value) in state.entries)
        if (key != id) key: value,
      if (count > 0) id: count,
    };
  }

  void clear() => state = {};
}

final cartProvider = NotifierProvider<Cart, Map<String, int>>(Cart.new);

int totalOf(Map<String, int> cart, List<Drink> menu) =>
    menu.fold(0, (sum, drink) => sum + drink.price * (cart[drink.id] ?? 0));

final orderProvider = FutureProvider.family<Order, String>((ref, id) => ref.watch(apiProvider).order(id));
""",
    "lib/features/menu/menu_page.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../design/tokens.dart';
import '../../state/providers.dart';

// {w_c_features}
class MenuPage extends ConsumerWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menu = ref.watch(menuProvider);
    final count = ref.watch(cartProvider).values.fold(0, (a, b) => a + b);
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('{w_menu}'),
        actions: [
          IconButton(
            tooltip: '{w_open_cart}',
            onPressed: () => context.go('/cart'),
            // {w_c_motion}
            icon: AnimatedSwitcher(
              duration: reduce ? Duration.zero : const Duration(milliseconds: 200),
              child: Badge.count(key: ValueKey(count), count: count, isLabelVisible: count > 0, child: const Icon(Icons.local_cafe)),
            ),
          ),
        ],
      ),
      body: switch (menu) {
        AsyncData(value: (final drinks, fresh: _)) => ListView.builder(
          // {w_c_lazy}
          itemCount: drinks.length,
          itemBuilder: (context, i) {
            final drink = drinks[i];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.s),
              title: Text(drink.name),
              subtitle: Text('${drink.about}\\n${drink.price} {w_egp}'),
              isThreeLine: true,
              trailing: IconButton.filled(
                tooltip: '{w_add} ${drink.name}',
                onPressed: () => ref.read(cartProvider.notifier).add(drink.id),
                // {w_c_icon}
                icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
              ),
            );
          },
        ),
        AsyncError() => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: Space.m,
            children: [
              const Text('{w_failed}'),
              FilledButton(onPressed: () => ref.invalidate(menuProvider), child: const Text('{w_retry}')),
            ],
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
""",
    "lib/features/cart/cart_page.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../design/tokens.dart';
import '../../state/providers.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final menu = ref.watch(menuProvider).value?.$1 ?? const [];
    final lines = [for (final drink in menu) if (cart[drink.id] case final count?) (drink, count)];
    final total = totalOf(cart, menu);
    return Scaffold(
      appBar: AppBar(title: const Text('{w_cart}')),
      body: lines.isEmpty
          ? const Center(child: Text('{w_empty}'))
          : ListView(
              children: [
                for (final (drink, count) in lines)
                  ListTile(
                    title: Text(drink.name),
                    subtitle: Text('$count × ${drink.price} {w_egp}'),
                    trailing: IconButton(
                      tooltip: '{w_remove} ${drink.name}',
                      onPressed: () => ref.read(cartProvider.notifier).remove(drink.id),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: lines.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Space.m),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: Space.s,
                  children: [
                    Text('{w_total}: $total {w_egp}', style: Theme.of(context).textTheme.titleLarge),
                    FilledButton(
                      onPressed: () async {
                        final order = await ref.read(apiProvider).place(cart);
                        ref.read(cartProvider.notifier).clear();
                        if (context.mounted) {
                          context.go('/orders/${order.id}');
                        }
                      },
                      child: const Text('{w_place}'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
""",
    "lib/features/orders/order_page.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/models.dart';
import '../../design/tokens.dart';
import '../../state/providers.dart';

class OrderPage extends ConsumerWidget {
  const OrderPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderProvider(id));
    final status = order.value?.status;
    return Scaffold(
      appBar: AppBar(title: Text('{w_order} $id')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(orderProvider(id).future),
        child: ListView(
          padding: const EdgeInsets.all(Space.l),
          children: [
            for (final (step, label) in const [
              (OrderStatus.received, '{w_received}'),
              (OrderStatus.preparing, '{w_preparing}'),
              (OrderStatus.ready, '{w_ready}'),
            ])
              ListTile(
                leading: Icon(
                  status != null && status.index >= step.index ? Icons.check_circle : Icons.radio_button_unchecked,
                ),
                title: Text(label),
                selected: status == step,
              ),
          ],
        ),
      ),
    );
  }
}
""",
    "lib/router.dart": """import 'package:go_router/go_router.dart';

import 'features/cart/cart_page.dart';
import 'features/menu/menu_page.dart';
import 'features/orders/order_page.dart';

// {w_c_router}
GoRouter cafeRouter() => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MenuPage(),
      routes: [
        GoRoute(path: 'cart', builder: (context, state) => const CartPage()),
        GoRoute(path: 'orders/:id', builder: (context, state) => OrderPage(id: state.pathParameters['id']!)),
      ],
    ),
  ],
);
""",
    "lib/observe/crashes.dart": """import 'dart:ui';

import 'package:material_ui/material_ui.dart';

class Crashes {
  Crashes(this.send);

  final void Function(Map<String, Object?> report) send;

  void install() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      send({'type': details.exception.runtimeType.toString(), 'fatal': false});
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      send({'type': error.runtimeType.toString(), 'fatal': true});
      return true;
    };
  }
}
""",
    "lib/cafe_app.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'router.dart';

class CafeApp extends StatefulWidget {
  const CafeApp({super.key});

  @override
  State<CafeApp> createState() => _CafeAppState();
}

class _CafeAppState extends State<CafeApp> {
  final GoRouter router = cafeRouter();

  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
{w_locale}      title: '{w_title}',
      theme: ThemeData(colorSchemeSeed: Colors.brown),
      darkTheme: ThemeData(colorSchemeSeed: Colors.brown, brightness: Brightness.dark),
      routerConfig: router,
    );
  }
}

Widget cafe({List<Override> overrides = const []}) => ProviderScope(
  overrides: overrides,
  retry: (count, error) => null,
  child: const CafeApp(),
);
""",
    "lib/main_cafe.dart": """import 'package:material_ui/material_ui.dart';

import 'cafe_app.dart';
import 'observe/crashes.dart';

// {w_c_main}
void main() {
  Crashes((report) => debugPrint('report: $report')).install();
  runApp(cafe());
}
""",
    "test/fakes.dart": """import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:bit_app/data/cafe_api.dart';
import 'package:bit_app/data/models.dart';

class FakeApi implements CafeApi {
  var placed = <Map<String, int>>[];

  @override
  Future<List<Drink>> menu() async => const [
    Drink('latte', 'Latte', 'Espresso and steamed milk', 45),
    Drink('cake', 'Cherry cake', 'Baked this morning', 55),
  ];

  @override
  Future<Order> place(Map<String, int> lines) async {
    placed.add(lines);
    return const Order('41', OrderStatus.received);
  }

  @override
  Future<Order> order(String id) async => Order(id, OrderStatus.ready);
}

SharedPreferencesAsync memoryPrefs() {
  SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  return SharedPreferencesAsync();
}
""",
    "test/cart_test.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/data/models.dart';
import 'package:bit_app/state/providers.dart';

void main() {
  test('{w_t_cart}', () {
    final container = ProviderContainer.test();
    final cart = container.read(cartProvider.notifier)
      ..add('latte')
      ..add('latte')
      ..add('cake')
      ..remove('cake');
    const menu = [Drink('latte', 'Latte', '', 45), Drink('cake', 'Cherry cake', '', 55)];
    expect(container.read(cartProvider), {'latte': 2});
    expect(totalOf(container.read(cartProvider), menu), 90);
    cart.clear();
    expect(container.read(cartProvider), isEmpty);
  });
}
""",
    "test/menu_cache_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/data/menu_repository.dart';

import 'fakes.dart';

void main() {
  test('{w_t_cache}', () async {
    final prefs = memoryPrefs();
    final repository = MenuRepository(FakeApi(), prefs);
    final first = await repository.watch().toList();
    final second = await repository.watch().toList();
    debugPrint('first launch:  ${[for (final (menu, :fresh) in first) '${menu.length} drinks, fresh: $fresh']}');
    debugPrint('second launch: ${[for (final (menu, :fresh) in second) '${menu.length} drinks, fresh: $fresh']}');
    expect(second, hasLength(2));
  });
}
""",
    "test/journey_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/cafe_app.dart';
import 'package:bit_app/state/providers.dart';

import 'fakes.dart';

void main() {
  testWidgets('{w_t_journey}', (tester) async {
    final api = FakeApi();
    await tester.pumpWidget(cafe(overrides: [apiProvider.overrideWithValue(api), prefsProvider.overrideWithValue(memoryPrefs())]));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('{w_add} Latte'));
    await tester.tap(find.byTooltip('{w_add} Latte'));
    await tester.tap(find.byTooltip('{w_add} Cherry cake'));
    await tester.tap(find.byTooltip('{w_open_cart}'));
    await tester.pumpAndSettle();
    expect(find.text('{w_total}: 145 {w_egp}'), findsOneWidget);
    await tester.tap(find.text('{w_place}'));
    await tester.pumpAndSettle();
    expect(find.text('{w_order} 41'), findsOneWidget);
    expect(api.placed.single, {'latte': 2, 'cake': 1});
  });
}
""",
    "test/a11y_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe_app.dart';
import 'package:bit_app/state/providers.dart';

import 'fakes.dart';

void main() {
  testWidgets('{w_t_a11y}', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(cafe(overrides: [apiProvider.overrideWithValue(FakeApi()), prefsProvider.overrideWithValue(memoryPrefs())]));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('{w_add} Latte'));
    for (final page in ['menu', 'cart']) {
      if (page == 'cart') {
        await tester.tap(find.byTooltip('{w_open_cart}'));
        await tester.pumpAndSettle();
      }
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      debugPrint('$page: labels, tap targets and contrast pass');
    }
    semantics.dispose();
  });
}
""",
    "root/integration_test/journey_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('{w_t_journey}', (tester) async {
    await tester.pumpWidget(cafe());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('{w_add} {w_latte}'));
    await tester.tap(find.byTooltip('{w_add} {w_cake}'));
    await tester.tap(find.byTooltip('{w_open_cart}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('{w_place}'));
    await tester.pumpAndSettle();
    expect(find.text('{w_preparing}'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    final ready = tester.widget<ListTile>(find.widgetWithText(ListTile, '{w_ready}'));
    debugPrint('order 41: ${ready.selected ? 'ready' : 'not ready'} after a pull to refresh');
    expect(ready.selected, isTrue);
  });
}
""",
    "root/tool/ci.sh": """#!/bin/sh
set -e
echo "== format"
dart format --output=none --set-exit-if-changed lib test
echo "== analyze"
flutter analyze
echo "== test"
flutter test --coverage
echo "== build"
flutter build web --release -t lib/main_cafe.dart
""",
    # Projects
    "lib/state/favorites.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

class Favorites extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async => (await ref.watch(prefsProvider).getStringList('favorites') ?? const []).toSet();

  Future<void> toggle(String id) async {
    final current = await future;
    final next = current.contains(id) ? ({...current}..remove(id)) : {...current, id};
    await ref.read(prefsProvider).setStringList('favorites', next.toList()..sort());
    state = AsyncData(next);
  }
}

final favoritesProvider = AsyncNotifierProvider<Favorites, Set<String>>(Favorites.new);
""",
    "test/favorites_test.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/state/favorites.dart';
import 'package:bit_app/state/providers.dart';

import 'fakes.dart';

void main() {
  test('{w_t_fav}', () async {
    final prefs = memoryPrefs();
    final first = ProviderContainer.test(overrides: [prefsProvider.overrideWithValue(prefs)]);
    await first.read(favoritesProvider.future);
    await first.read(favoritesProvider.notifier).toggle('latte');
    await first.read(favoritesProvider.notifier).toggle('cake');
    await first.read(favoritesProvider.notifier).toggle('latte');
    final later = ProviderContainer.test(overrides: [prefsProvider.overrideWithValue(prefs)]);
    debugPrint('after a restart: ${await later.read(favoritesProvider.future)}');
    expect(await later.read(favoritesProvider.future), {'cake'});
  });
}
""",
    "test/robust_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe_app.dart';
import 'package:bit_app/state/providers.dart';

import 'fakes.dart';

void main() {
  testWidgets('{w_t_robust}', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.pumpWidget(cafe(overrides: [apiProvider.overrideWithValue(FakeApi()), prefsProvider.overrideWithValue(memoryPrefs())]));
    await tester.pumpAndSettle();
    final checked = <String>[];
    void check(String page) {
      expect(tester.takeException(), isNull, reason: page);
      checked.add(page);
    }

    check('menu');
    await tester.tap(find.byTooltip('{w_add} Latte'));
    await tester.tap(find.byTooltip('{w_open_cart}'));
    await tester.pumpAndSettle();
    check('cart');
    await tester.tap(find.text('{w_place}'));
    await tester.pumpAndSettle();
    check('order');
    debugPrint('dark theme, text at 200%, 360 x 640: ${checked.join(', ')} without overflow');
  });
}
""",
    "lib/data/outbox.dart": """import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import 'cafe_api.dart';
import 'models.dart';

// {w_c_outbox}
class Outbox {
  Outbox(this.api, this.prefs);

  final CafeApi api;
  final SharedPreferencesAsync prefs;

  Future<Order?> place(Map<String, int> lines) async {
    try {
      return await api.place(lines);
    } on SocketException {
      final waiting = await prefs.getStringList('outbox') ?? [];
      await prefs.setStringList('outbox', [...waiting, jsonEncode(lines)]);
      return null;
    }
  }

  Future<int> flush() async {
    final waiting = await prefs.getStringList('outbox') ?? [];
    var sent = 0;
    for (final lines in waiting) {
      try {
        await api.place((jsonDecode(lines) as Map<String, Object?>).cast<String, int>());
        sent++;
      } on SocketException {
        break;
      }
    }
    await prefs.setStringList('outbox', waiting.sublist(sent));
    return sent;
  }
}
""",
    "test/outbox_test.dart": """import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/data/models.dart';
import 'package:bit_app/data/outbox.dart';

import 'fakes.dart';

class FlakyApi extends FakeApi {
  var online = false;

  @override
  Future<Order> place(Map<String, int> lines) {
    if (!online) {
      throw const SocketException('Network is unreachable');
    }
    return super.place(lines);
  }
}

void main() {
  test('{w_t_outbox}', () async {
    final api = FlakyApi();
    final outbox = Outbox(api, memoryPrefs());
    final order = await outbox.place({'latte': 1});
    debugPrint('offline: order ${order?.id ?? 'queued'}, sent to the server: ${api.placed.length}');
    expect(await outbox.flush(), 0);
    api.online = true;
    debugPrint('back online: ${await outbox.flush()} sent, server received ${api.placed}');
    expect(await outbox.flush(), 0);
  });
}
""",
}

SHOTS = [
    ("menu.png", "lib/main_cafe.dart", "wait=1200"),
    ("cart.png", "lib/main_cafe.dart", "wait=1200|button={w_add} {w_latte}|button={w_add} {w_latte}|button={w_add} {w_cake}|button={w_open_cart}|wait=900"),
    ("order.png", "lib/main_cafe.dart", "wait=1200|button={w_add} {w_latte}|button={w_open_cart}|wait=600|button={w_place}|wait=3000"),
]

TESTS = [
    ("cart-test.sh", "test/cart_test.dart"),
    ("cache-test.sh", "test/menu_cache_test.dart"),
    ("journey-test.sh", "test/journey_test.dart"),
    ("a11y-test.sh", "test/a11y_test.dart"),
    ("projects/favorites-test.sh", "test/favorites_test.dart"),
    ("projects/robust-test.sh", "test/robust_test.dart"),
    ("projects/outbox-test.sh", "test/outbox_test.dart"),
]


def whole(lang):
    """The integration test on Linux, the CI script, and the shape of the project."""
    project = WORK / HERE.name / lang / "bit_app"
    out = HERE / lang
    (project / "lib" / "main.dart").unlink(missing_ok=True)  # flutter create's counter app; main_cafe.dart is the entry
    s = Session(project)
    s.run("flutter test integration_test/journey_test.dart -d linux")
    s.save(out / "integration-test.sh")
    s.run("sh tool/ci.sh", keep=lambda lines: [l for l in lines if l.startswith(("$", "==", "No issues", "✓"))
                                               or "All tests passed" in l])
    s.save(out / "ci.sh")
    s.run("find lib -name '*.dart' | sort | grep -v gallery")
    s.save(out / "tree.sh")


def main():
    screen = ":98"
    xvfb = subprocess.Popen(["Xvfb", screen, "-screen", "0", "1024x768x24", "-ac"],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.environ["DISPLAY"] = screen
    try:
        flutter_gallery(HERE, T, FILES, SHOTS, TESTS,
                        packages=["flutter_riverpod", "go_router", "shared_preferences",
                                  "'dev:shared_preferences_platform_interface'",
                                  "'dev:integration_test:{\"sdk\":\"flutter\"}'"])
        for lang in T:
            whole(lang)
    finally:
        xvfb.terminate()


if __name__ == "__main__":
    main()
