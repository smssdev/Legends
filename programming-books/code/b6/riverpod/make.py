"""Writes the examples of Book 6, chapter "State Management with Riverpod", in English and Arabic. The domain and
data layers are Chapter 2's, unchanged; only the presentation moves to Riverpod. Tests count rebuilds, show
automatic retries, and override dependencies in one line.
Run: python3 make.py   (needs Flutter 3.50.1, Node.js and Playwright's Chromium)
"""
import importlib.util
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent.parent / "b5"))
from kit import flutter_gallery  # noqa: E402

# Chapter 2's layers, reused as they are.
spec = importlib.util.spec_from_file_location("ch2", HERE.parent / "architecture" / "make.py")
ch2 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ch2)
KEEP = [k for k in ch2.FILES if k.startswith(("lib/core/", "lib/features/orders/domain/", "lib/features/orders/data/"))
        and "cancel_order" not in k and "http_orders" not in k]

T = {
    "en": dict(ch2.T["en"], **dict(
        w_c_deps="Dependencies are providers too: the app reads them, tests replace them.",
        w_c_build="Providers build each other: change the source, and everything above it is rebuilt.",
        w_c_history="Loading, ready or failed: FutureProvider gives the screen an AsyncValue.",
        w_c_wiring="The feature's wiring: the only file of the feature that knows the data layer.",
        w_c_immutable="A new map every time: Riverpod notifies when state is a different object.",
        w_c_count="Derived state: recomputed only when the basket changes.",
        w_c_place="Placing an order: loading while it runs, then the result.",
        w_c_mounted="The screen may have closed while waiting.",
        w_c_invalidate="The history is stale now: throw it away, and it loads again for whoever watches it.",
        w_c_fixed="Fixed at 10:00 for the book's screenshots; a real app keeps DateTime.now.",
        w_c_closed2="One override: the clock says 23:00.",
        w_c_offline2="One override: a source that always fails.",
        w_c_states="Every state of the history, in one switch.",
        w_c_badge="Watches only the count, so it rebuilds only when the count changes.",
        w_history_failed="Could not load your orders", w_retry="Retry",
        w_t_override="one override, and the rules run without the network",
        w_t_retry="a failing provider is retried, unless retries are turned off",
        w_t_select="select rebuilds only when the selected value changes",
        w_t_page2="adding, placing, and the history refreshed",
        w_t_family="each order id has its own provider, cached",
        w_t_search="only the last query is searched",
        w_t_undo="undo goes back one state at a time",
        w_search="Search the menu", w_undo="Undo",
        w_c_family="One provider per id: orderProvider(1) and orderProvider(2) are separate, each cached.",
        w_c_auto="autoDispose: when nobody watches this query any more, it is thrown away.",
        w_c_debounce="Wait a little; if the person typed again, this query was disposed and is not searched.",
        w_c_undo="Immutable states make undo simple: keep the old ones.",
    )),
    "ar": dict(ch2.T["ar"], **dict(
        w_c_deps="الاعتماديات providers أيضاً: التطبيق يقرؤها، والاختبارات تستبدلها.",
        w_c_build="الـ providers يبني بعضها بعضاً: غيّر المصدر، فيُعاد بناء كل ما فوقه.",
        w_c_history="تحميل أو جاهز أو فاشل: FutureProvider تعطي الشاشة AsyncValue.",
        w_c_wiring="توصيل الميزة: الملف الوحيد في الميزة الذي يعرف طبقة البيانات.",
        w_c_immutable="خريطة جديدة في كل مرة: يبلّغ Riverpod حين تكون الحالة كائناً مختلفاً.",
        w_c_count="حالة مشتقة: تُحسب من جديد فقط حين تتغير السلة.",
        w_c_place="إرسال الطلب: تحميل أثناء العمل، ثم النتيجة.",
        w_c_mounted="ربما أُغلقت الشاشة أثناء الانتظار.",
        w_c_invalidate="السجل قديم الآن: ارمه، فيُحمَّل من جديد لمن يشاهده.",
        w_c_fixed="مثبتة على 10:00 لصور الكتاب؛ والتطبيق الحقيقي يُبقي DateTime.now.",
        w_c_closed2="استبدال واحد: الساعة تقول 23:00.",
        w_c_offline2="استبدال واحد: مصدر يفشل دائماً.",
        w_c_states="كل حالات السجل، في switch واحد.",
        w_c_badge="يشاهد العدد وحده، فلا يُعاد بناؤه إلا حين يتغير العدد.",
        w_history_failed="تعذّر تحميل طلباتك", w_retry="أعد المحاولة",
        w_t_override="استبدال واحد، والقواعد تعمل بلا شبكة",
        w_t_retry="الـ provider الفاشل يُعاد، ما لم تُطفأ إعادة المحاولة",
        w_t_select="select تعيد البناء فقط حين تتغير القيمة المختارة",
        w_t_page2="الإضافة والإرسال وتحديث السجل",
        w_t_family="لكل رقم طلب provider خاص به، محفوظ",
        w_t_search="آخر بحث وحده يُنفَّذ",
        w_t_undo="التراجع يعود حالة واحدة في كل مرة",
        w_search="ابحث في القائمة", w_undo="تراجع",
        w_c_family="provider لكل رقم: orderProvider(1) وorderProvider(2) منفصلان، وكل منهما محفوظ.",
        w_c_auto="autoDispose: حين لا يشاهد أحد هذا البحث يُرمى.",
        w_c_debounce="انتظر قليلاً؛ فإن كتب الشخص من جديد يكون هذا البحث قد رُمي، فلا يُنفَّذ.",
        w_c_undo="الحالات التي لا تتغير تجعل التراجع بسيطاً: احتفظ بالقديمة.",
    )),
}

F = "lib/features/orders/"
P = F + "presentation/"
FILES = {k: ch2.FILES[k] for k in KEEP}
# The history fails too when the source is offline, after the same delay as a network.
FILES[F + "data/orders_source.dart"] = ch2.FILES[F + "data/orders_source.dart"].replace(
    "  Future<List<Map<String, dynamic>>> list() async => [..._orders];",
    """  Future<List<Map<String, dynamic>>> list() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (fails) {
      throw Exception('connection refused');
    }
    return [..._orders];
  }""")
assert "milliseconds: 400));\n    if (fails) {\n      throw Exception('connection refused');\n    }\n    return [..." in FILES[F + "data/orders_source.dart"]

NAMES = ch2.FILES[P + "orders_page.dart"].split("class OrdersPage")[0].split("import 'orders_controller.dart';\n")[1]

APP = """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'features/orders/presentation/orders_page.dart';
import 'features/orders/providers.dart';
%s
void main() {
  runApp(
    ProviderScope(
      // %s
      overrides: [%s],
      child: const OrdersApp(),
    ),
  );
}
"""

FILES.update({
    F + "providers.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/orders_repository_impl.dart';
import 'data/orders_source.dart';
import 'domain/order.dart';
import 'domain/orders_repository.dart';
import 'domain/place_order.dart';

// {w_c_wiring}

// {w_c_deps}
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
final ordersSourceProvider = Provider<OrdersSource>((ref) => FakeOrdersSource());

// {w_c_build}
final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => OrdersRepositoryImpl(ref.watch(ordersSourceProvider)),
);
final placeOrderProvider = Provider<PlaceOrder>(
  (ref) => PlaceOrder(ref.watch(ordersRepositoryProvider), clock: ref.watch(clockProvider)),
);

// {w_c_history}
final historyProvider = FutureProvider<List<Order>>((ref) => ref.watch(ordersRepositoryProvider).history());
""",
    P + "basket.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/order.dart';

class BasketNotifier extends Notifier<Map<MenuItem, int>> {
  @override
  Map<MenuItem, int> build() => const {};

  // {w_c_immutable}
  void add(MenuItem item) => state = {...state, item: (state[item] ?? 0) + 1};

  void clear() => state = const {};
}

final basketProvider = NotifierProvider<BasketNotifier, Map<MenuItem, int>>(BasketNotifier.new);

// {w_c_count}
final basketCountProvider = Provider<int>((ref) => ref.watch(basketProvider).values.fold(0, (a, b) => a + b));
""",
    P + "place_controller.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result.dart';
import '../domain/failures.dart';
import '../domain/order.dart';
import '../providers.dart';
import 'basket.dart';

typedef Outcome = Result<Order, OrderFailure>;

// {w_c_place}
class PlaceController extends AsyncNotifier<Outcome?> {
  @override
  Future<Outcome?> build() async => null;

  Future<void> place() async {
    state = const AsyncLoading();
    final lines = [for (final e in ref.read(basketProvider).entries) OrderLine(e.key, e.value)];
    final result = await ref.read(placeOrderProvider)(lines);
    // {w_c_mounted}
    if (!ref.mounted) {
      return;
    }
    if (result is Ok) {
      ref.read(basketProvider.notifier).clear();
      // {w_c_invalidate}
      ref.invalidate(historyProvider);
    }
    state = AsyncData(result);
  }
}

final placeControllerProvider = AsyncNotifierProvider<PlaceController, Outcome?>(PlaceController.new);
""",
    P + "messages.dart": """import '../domain/failures.dart';

// {w_c_words}
String describe(OrderFailure failure) => switch (failure) {
  EmptyOrder() => '{w_m_empty}',
  TooLarge() => '{w_m_large}',
  Closed() => '{w_m_closed}',
  NetworkFailure() => '{w_m_network}',
};
""",
    P + "orders_page.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/result.dart';
import '../domain/order.dart';
import '../providers.dart';
import 'basket.dart';
import 'messages.dart';
import 'place_controller.dart';
""" + NAMES + """class OrdersApp extends StatelessWidget {
  const OrdersApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    {w_rtl}
    theme: ThemeData(colorSchemeSeed: Colors.brown),
    home: const OrdersPage(),
  );
}

// {w_c_badge}
class BasketBadge extends ConsumerWidget {
  const BasketBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(basketCountProvider);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 16),
      child: Badge(label: Text('$count'), isLabelVisible: count > 0, child: const Icon(Icons.shopping_basket)),
    );
  }
}

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basket = ref.watch(basketProvider);
    final outcome = ref.watch(placeControllerProvider);
    final history = ref.watch(historyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('{w_title}'), actions: const [BasketBadge()]),
      body: ListView(
        children: [
          for (final item in menu)
            ListTile(
              title: Text(names[item.id]!),
              subtitle: Text('${item.price.pounds} {w_egp}'),
              leading: CircleAvatar(child: Text('${basket[item] ?? 0}')),
              trailing: IconButton(
                tooltip: '{w_add} ${names[item.id]}',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => ref.read(basketProvider.notifier).add(item),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: outcome.isLoading ? null : () => ref.read(placeControllerProvider.notifier).place(),
              child: Text(outcome.isLoading ? '{w_placing}' : '{w_place}'),
            ),
          ),
          if (outcome.value case final result?)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(switch (result) {
                    Ok(:final value) => '{w_m_placed}: {w_order_n} ${value.id}',
                    Err(:final failure) => describe(failure),
                  }),
                ),
              ),
            ),
          ListTile(title: Text('{w_history}', style: Theme.of(context).textTheme.titleMedium)),
          // {w_c_states}
          ...switch (history) {
            AsyncValue(:final value?) when value.isEmpty => [const ListTile(title: Text('{w_nothing}'))],
            AsyncValue(:final value?) => [
              for (final order in value)
                ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: Text('{w_order_n} ${order.id} · ${order.total.pounds} {w_egp}'),
                  subtitle: Text('{w_items}: ${order.items} · ${statusNames[order.status]}'),
                ),
            ],
            AsyncValue(hasError: true) => [
              ListTile(
                leading: const Icon(Icons.cloud_off),
                title: const Text('{w_history_failed}'),
                trailing: TextButton(onPressed: () => ref.invalidate(historyProvider), child: const Text('{w_retry}')),
              ),
            ],
            _ => [const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))],
          },
        ],
      ),
    );
  }
}
""",
    "lib/orders_app.dart": APP % ("", "{w_c_fixed}", "clockProvider.overrideWithValue(() => DateTime(2026, 11, 22, 10))"),
    "lib/orders_closed.dart": APP % ("", "{w_c_closed2}", "clockProvider.overrideWithValue(() => DateTime(2026, 11, 22, 23))"),
    "lib/orders_offline.dart": APP % (
        "import 'features/orders/data/orders_source.dart';\n", "{w_c_offline2}",
        "\n        clockProvider.overrideWithValue(() => DateTime(2026, 11, 22, 10)),\n"
        "        ordersSourceProvider.overrideWithValue(FakeOrdersSource(fails: true)),\n      "),
    "test/override_test.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/core/result.dart';
import 'package:bit_app/features/orders/data/orders_source.dart';
import 'package:bit_app/features/orders/domain/failures.dart';
import 'package:bit_app/features/orders/domain/order.dart';
import 'package:bit_app/features/orders/presentation/basket.dart';
import 'package:bit_app/features/orders/presentation/place_controller.dart';
import 'package:bit_app/features/orders/providers.dart';

class CountingSource extends FakeOrdersSource {
  var posts = 0;

  @override
  Future<Map<String, dynamic>> post(Map<String, int> items) {
    posts++;
    return super.post(items);
  }
}

void main() {
  test('{w_t_override}', () async {
    final source = CountingSource();
    final container = ProviderContainer.test(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 22, 23)),
        ordersSourceProvider.overrideWithValue(source),
      ],
    );
    container.read(basketProvider.notifier).add(menu.first);
    await container.read(placeControllerProvider.notifier).place();

    final outcome = container.read(placeControllerProvider).value;
    expect((outcome! as Err).failure, isA<Closed>());
    expect(source.posts, 0);
    expect(container.read(basketCountProvider), 1);
  });
}
""",
    "test/retry_test.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/features/orders/data/orders_source.dart';
import 'package:bit_app/features/orders/domain/order.dart';
import 'package:bit_app/features/orders/providers.dart';

String show(AsyncValue<List<Order>> v) => switch (v) {
  AsyncValue(:final value?) => 'data: ${value.length} orders',
  AsyncValue(:final error?) => 'error: $error, still loading: ${v.isLoading}',
  _ => 'loading',
};

Future<String> historyAfter(ProviderContainer container, Duration wait) async {
  container.listen(historyProvider, (previous, next) {});
  await Future<void>.delayed(wait);
  return show(container.read(historyProvider));
}

void main() {
  test('{w_t_retry}', () async {
    final offline = ordersSourceProvider.overrideWithValue(FakeOrdersSource(fails: true));

    final retrying = ProviderContainer.test(overrides: [offline]);
    debugPrint('default:    ${await historyAfter(retrying, const Duration(milliseconds: 600))}');

    final once = ProviderContainer.test(overrides: [offline], retry: (count, error) => null);
    debugPrint('no retries: ${await historyAfter(once, const Duration(milliseconds: 600))}');
    expect(once.read(historyProvider).isLoading, isFalse);
  });
}
""",
    "test/select_test.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/features/orders/domain/order.dart';
import 'package:bit_app/features/orders/presentation/basket.dart';

final builds = {'whole basket': 0, 'select isEmpty': 0};

void main() {
  testWidgets('{w_t_select}', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              Consumer(
                builder: (context, ref, _) {
                  ref.watch(basketProvider);
                  builds['whole basket'] = builds['whole basket']! + 1;
                  return const SizedBox();
                },
              ),
              Consumer(
                builder: (context, ref, _) {
                  ref.watch(basketProvider.select((b) => b.isEmpty));
                  builds['select isEmpty'] = builds['select isEmpty']! + 1;
                  return const SizedBox();
                },
              ),
            ],
          ),
        ),
      ),
    );
    final container = ProviderScope.containerOf(tester.element(find.byType(Column)));
    for (var i = 0; i < 3; i++) {
      container.read(basketProvider.notifier).add(menu[i]);
      await tester.pump();
    }
    debugPrint('$builds');
    expect(builds, {'whole basket': 4, 'select isEmpty': 2});
  });
}
""",
    "test/page_test.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/features/orders/presentation/orders_page.dart';
import 'package:bit_app/features/orders/providers.dart';

void main() {
  testWidgets('{w_t_page2}', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [clockProvider.overrideWithValue(() => DateTime(2026, 11, 22, 10))],
        child: const OrdersApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('{w_nothing}'), findsOneWidget);

    await tester.tap(find.byTooltip('{w_add} {w_latte}'));
    await tester.tap(find.byTooltip('{w_add} {w_cake}'));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text('{w_place}'));
    await tester.pumpAndSettle();
    expect(find.text('{w_order_n} 1 · 105 {w_egp}'), findsOneWidget);
  });
}
""",
    # Projects
    F + "order_provider.dart": """import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/order.dart';
import 'providers.dart';

// {w_c_family}
final orderProvider = FutureProvider.family<Order?, int>((ref, id) async {
  final all = await ref.watch(historyProvider.future);
  return all.firstWhereOrNull((o) => o.id == id);
});
""",
    "test/family_test.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/features/orders/domain/order.dart';
import 'package:bit_app/features/orders/order_provider.dart';
import 'package:bit_app/features/orders/providers.dart';

void main() {
  test('{w_t_family}', () async {
    final container = ProviderContainer.test(overrides: [clockProvider.overrideWithValue(() => DateTime(2026, 11, 22, 10))]);
    final place = container.read(placeOrderProvider);
    await place([OrderLine(menu[0], 1)]);
    await place([OrderLine(menu[1], 2)]);

    final first = await container.read(orderProvider(1).future);
    final second = await container.read(orderProvider(2).future);
    expect(first!.total.pounds, 45);
    expect(second!.total.pounds, 50);
    expect(await container.read(orderProvider(3).future), isNull);
    // {w_c_same}
    expect(identical(await container.read(orderProvider(1).future), first), isTrue);
  });
}
""",
    "projects/search.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'features/orders/domain/order.dart';
""" + NAMES.replace("// {w_c_status}", "// {w_c_status}") + """
var searches = <String>[];

// {w_c_auto}
final searchProvider = FutureProvider.autoDispose.family<List<MenuItem>, String>((ref, query) async {
  var disposed = false;
  ref.onDispose(() => disposed = true);
  // {w_c_debounce}
  await Future<void>.delayed(const Duration(milliseconds: 300));
  if (disposed) {
    return const [];
  }
  searches.add(query);
  return [
    for (final item in menu)
      if (names[item.id]!.toLowerCase().contains(query.toLowerCase())) item,
  ];
});

final queryProvider = NotifierProvider<QueryNotifier, String>(QueryNotifier.new);

class QueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String text) => state = text;
}

void main() {
  runApp(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        {w_rtl}
        theme: ThemeData(colorSchemeSeed: Colors.brown),
        home: const SearchPage(),
      ),
    ),
  );
}

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchProvider(ref.watch(queryProvider)));
    return Scaffold(
      appBar: AppBar(title: const Text('{w_search}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(labelText: '{w_search}', prefixIcon: Icon(Icons.search)),
              onChanged: ref.read(queryProvider.notifier).set,
            ),
          ),
          Expanded(
            child: switch (results) {
              AsyncValue(:final value?) => ListView(
                children: [
                  for (final item in value)
                    ListTile(title: Text(names[item.id]!), trailing: Text('${item.price.pounds} {w_egp}')),
                ],
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}
""",
    "test/search_test.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_search.dart';

void main() {
  testWidgets('{w_t_search}', (tester) async {
    searches = [];
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: SearchPage())));
    await tester.pump(const Duration(milliseconds: 400));
    for (final text in ['{w_s1}', '{w_s2}', '{w_s3}']) {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 400));
    expect(searches, ['', '{w_s3}']);
    expect(find.text('{w_tea}'), findsOneWidget);
  });
}
""",
    P + "undo_basket.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/order.dart';

// {w_c_undo}
class UndoBasket extends Notifier<Map<MenuItem, int>> {
  final _past = <Map<MenuItem, int>>[];

  @override
  Map<MenuItem, int> build() => const {};

  bool get canUndo => _past.isNotEmpty;

  void _set(Map<MenuItem, int> next) {
    _past.add(state);
    state = next;
  }

  void add(MenuItem item) => _set({...state, item: (state[item] ?? 0) + 1});

  void remove(MenuItem item) {
    final n = state[item] ?? 0;
    if (n == 0) {
      return;
    }
    _set(n == 1 ? ({...state}..remove(item)) : {...state, item: n - 1});
  }

  void undo() {
    if (canUndo) {
      state = _past.removeLast();
    }
  }
}

final undoBasketProvider = NotifierProvider<UndoBasket, Map<MenuItem, int>>(UndoBasket.new);
""",
    "test/undo_test.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/features/orders/domain/order.dart';
import 'package:bit_app/features/orders/presentation/undo_basket.dart';

void main() {
  test('{w_t_undo}', () {
    final container = ProviderContainer.test();
    final basket = container.read(undoBasketProvider.notifier);
    final latte = menu[0];
    final cake = menu[2];
    final seen = <Map<MenuItem, int>>[];
    container.listen(undoBasketProvider, (previous, next) => seen.add(next));

    basket.add(latte);
    basket.add(latte);
    basket.add(cake);
    basket.remove(latte);
    expect(container.read(undoBasketProvider), {latte: 1, cake: 1});

    basket.undo();
    expect(container.read(undoBasketProvider), {latte: 2, cake: 1});
    basket.undo();
    basket.undo();
    expect(container.read(undoBasketProvider), {latte: 1});
    basket.undo();
    expect(container.read(undoBasketProvider), isEmpty);
    expect(basket.canUndo, isFalse);
    expect(seen, hasLength(8));
  });
}
""",
})
T["en"].update(w_s1="t", w_s2="te", w_s3="tea", w_c_same="The same id gives the same cached value.")
T["ar"]["w_m_closed"] = "المقهى مغلق، ونفتح من 8:00 إلى 22:00 كل يوم."
T["ar"].update(w_s1="ش", w_s2="شا", w_s3="شاي", w_c_same="الرقم نفسه يعطي القيمة المحفوظة نفسها.")

SHOTS = [
    ("placed.png", "lib/orders_app.dart",
     "button={w_add} {w_latte}|button={w_add} {w_latte}|button={w_add} {w_cake}|button={w_place}|wait=2000"),
    ("closed.png", "lib/orders_closed.dart", "button={w_add} {w_latte}|button={w_place}|wait=1000"),
    ("offline.png", "lib/orders_offline.dart", "button={w_add} {w_tea}|button={w_place}|wait=2000"),
    ("search.png", "projects/search.dart", "type={w_search}=>{w_s3}|wait=1000"),
]

TESTS = [
    ("override-test.sh", "test/override_test.dart"),
    ("retry-test.sh", "test/retry_test.dart"),
    ("select-test.sh", "test/select_test.dart"),
    ("page-test.sh", "test/page_test.dart"),
    ("projects/family-test.sh", "test/family_test.dart"),
    ("projects/search-test.sh", "test/search_test.dart"),
    ("projects/undo-test.sh", "test/undo_test.dart"),
]


def main():
    flutter_gallery(HERE, T, FILES, SHOTS, TESTS, packages=["flutter_riverpod", "collection"])


if __name__ == "__main__":
    main()
