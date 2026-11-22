"""Writes the examples of Book 6, chapter "Clean Architecture for Flutter", in English and Arabic: one feature
(café orders) in three layers, wired three ways, with tests for each layer and an architecture test that reads
the imports. Run: python3 make.py   (needs Flutter 3.50.1, Node.js and Playwright's Chromium)
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent.parent / "b5"))
from kit import flutter_gallery  # noqa: E402

T = {
    "en": dict(
        w_rtl="",
        w_title="Order", w_history="Your orders", w_place="Place order", w_placing="Placing…",
        w_nothing="Nothing ordered yet", w_add="Add", w_egp="EGP", w_basket="Basket", w_order_n="Order",
        w_latte="Latte", w_tea="Mint tea", w_cake="Cherry cake",
        w_m_empty="Add something to your basket first.",
        w_m_large="One order can hold at most 20 items.",
        w_m_closed="The café is closed. We open from 8:00 to 22:00.",
        w_m_network="No connection. Your basket is kept; try again.",
        w_m_placed="Order placed",
        w_c_result="A result is either a value or a failure; the type says which, and switch must handle both.",
        w_c_money="Money is a value: two amounts are equal when their numbers are equal.",
        w_c_entity="The order as the business sees it: no JSON, no widgets.",
        w_c_failures="Everything that can go wrong, as types. No text: words belong to the screen.",
        w_c_port="What the domain needs from the outside world. The data layer will provide it.",
        w_c_usecase="One action of the app, with its rules. It knows the repository only by its interface.",
        w_c_rules="The rules, in order: cheapest checks first, the network last.",
        w_c_dto="The shape of the data on the wire. It changes when the server changes; the entity does not.",
        w_c_source="Stands in for the server: answers in 400 ms, as a network would.",
        w_c_impl="Translates between the two worlds: DTOs to entities, exceptions to failures.",
        w_c_catch="Any failure of the source becomes a NetworkFailure: the domain never sees an exception.",
        w_c_controller="The screen's state and actions. It calls the use case, and turns failures into words.",
        w_c_words="Each failure, in the person's language.",
        w_c_root="The composition root: the only place that knows every concrete class.",
        w_c_closed="The same app, wired with a clock that says 23:00.",
        w_c_offline="The same app, wired with a source that always fails.",
        w_items="Items", w_pending="Pending", w_preparing="Preparing", w_ready="Ready", w_cancelled="Cancelled",
        w_c_status="The domain's statuses, in words: the domain has no text.",
        w_c_testkey="A new key for each hour: without it, Flutter would keep the first provider (Chapter 1).",
        w_c_rule="The domain imports only Dart and other domain files.",
        w_c_forbidden="What a domain file may never import.",
        w_t_place="placing an order follows the rules, in order",
        w_t_repo="the repository turns data into entities, and errors into failures",
        w_t_page="the page shows the placed order, or the failure in words",
        w_t_arch="the domain imports no Flutter, no data and no presentation",
        w_t_arch_bad="a domain file that imports Flutter is caught",
        # Projects
        w_t_cancel="an order can be cancelled only while pending, within five minutes",
        w_c_cancel="A new use case: no screen, no network, only the rules.",
        w_t_http="the HTTP source maps answers and errors",
        w_c_http="The same repository, with a real HTTP source: the domain does not change.",
        w_t_features="features talk to each other only through their domain",
        w_c_features="A feature may import another feature's domain, and nothing else of it.",
    ),
    "ar": dict(
        w_rtl="// من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.\n"
              "builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),\n",
        w_title="اطلب", w_history="طلباتك", w_place="أرسل الطلب", w_placing="جارٍ الإرسال…",
        w_nothing="لم تطلب شيئاً بعد", w_add="أضف", w_egp="جنيه", w_basket="السلة", w_order_n="الطلب",
        w_latte="لاتيه", w_tea="شاي بالنعناع", w_cake="كيك الكرز",
        w_m_empty="أضف شيئاً إلى سلتك أولاً.",
        w_m_large="الطلب الواحد يتسع لعشرين قطعة على الأكثر.",
        w_m_closed="المقهى مغلق. نفتح من 8:00 إلى 22:00.",
        w_m_network="لا اتصال. سلتك محفوظة؛ حاول من جديد.",
        w_m_placed="أُرسل الطلب",
        w_c_result="النتيجة إما قيمة وإما فشل؛ والنوع يقول أيهما، وswitch يجب أن يعالج الاثنين.",
        w_c_money="المال قيمة: المبلغان متساويان حين يتساوى رقماهما.",
        w_c_entity="الطلب كما يراه العمل: لا JSON ولا Widgets.",
        w_c_failures="كل ما قد يسوء، في صورة أنواع. بلا نصوص: الكلمات مكانها الشاشة.",
        w_c_port="ما يحتاجه المجال من العالم الخارجي. وطبقة البيانات ستقدّمه.",
        w_c_usecase="فعل واحد من أفعال التطبيق، بقواعده. ولا يعرف المستودع إلا بواجهته.",
        w_c_rules="القواعد بالترتيب: أرخص الفحوص أولاً، والشبكة أخيراً.",
        w_c_dto="شكل البيانات على الشبكة. يتغير حين يتغير الخادم؛ أما الكيان فلا.",
        w_c_source="ينوب عن الخادم: يجيب بعد 400 جزء من الثانية، كما تفعل الشبكة.",
        w_c_impl="يترجم بين العالمين: من DTO إلى كيانات، ومن الاستثناءات إلى حالات فشل.",
        w_c_catch="أي فشل في المصدر يصير NetworkFailure: فالمجال لا يرى استثناءً أبداً.",
        w_c_controller="حالة الشاشة وأفعالها. يستدعي حالة الاستخدام، ويحوّل حالات الفشل إلى كلمات.",
        w_c_words="كل فشل، بلغة الشخص.",
        w_c_root="جذر التركيب: المكان الوحيد الذي يعرف كل صنف حقيقي.",
        w_c_closed="التطبيق نفسه، موصولاً بساعة تقول 23:00.",
        w_c_offline="التطبيق نفسه، موصولاً بمصدر يفشل دائماً.",
        w_items="القطع", w_pending="معلّق", w_preparing="قيد التحضير", w_ready="جاهز", w_cancelled="ملغى",
        w_c_status="حالات المجال، بالكلمات: فالمجال بلا نصوص.",
        w_c_testkey="مفتاح جديد لكل ساعة: بدونه يُبقي Flutter الـ provider الأول (الفصل 1).",
        w_c_rule="المجال لا يستورد إلا Dart وملفات المجال الأخرى.",
        w_c_forbidden="ما لا يحق لملف في المجال أن يستورده أبداً.",
        w_t_place="إرسال الطلب يتبع القواعد، بالترتيب",
        w_t_repo="المستودع يحوّل البيانات إلى كيانات، والأخطاء إلى حالات فشل",
        w_t_page="الصفحة تعرض الطلب المرسل، أو الفشل بالكلمات",
        w_t_arch="المجال لا يستورد Flutter ولا البيانات ولا العرض",
        w_t_arch_bad="ملف في المجال يستورد Flutter يُكتشف",
        w_t_cancel="لا يُلغى الطلب إلا وهو معلّق، وخلال خمس دقائق",
        w_c_cancel="حالة استخدام جديدة: لا شاشة ولا شبكة، القواعد وحدها.",
        w_t_http="مصدر HTTP يحوّل الإجابات والأخطاء",
        w_c_http="المستودع نفسه، بمصدر HTTP حقيقي: لا يتغير المجال.",
        w_t_features="الميزات لا تكلّم بعضها إلا عبر مجالها",
        w_c_features="يحق للميزة أن تستورد مجال ميزة أخرى، ولا شيء غيره منها.",
    ),
}

D = "lib/features/orders/domain/"
DATA = "lib/features/orders/data/"
P = "lib/features/orders/presentation/"

APP = """import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'features/orders/data/orders_repository_impl.dart';
import 'features/orders/data/orders_source.dart';
import 'features/orders/domain/place_order.dart';
import 'features/orders/presentation/orders_controller.dart';
import 'features/orders/presentation/orders_page.dart';

// %s
void main() {
  final repository = OrdersRepositoryImpl(%s);
  final placeOrder = PlaceOrder(repository, clock: %s);
  runApp(
    ChangeNotifierProvider(
      create: (context) => OrdersController(placeOrder, repository),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        {w_rtl}
        theme: ThemeData(colorSchemeSeed: Colors.brown),
        home: const OrdersPage(),
      ),
    ),
  );
}
"""

FAKE_REPO = """class FakeRepository implements OrdersRepository {
  final placed = <List<OrderLine>>[];

  @override
  Future<Result<Order, OrderFailure>> place(List<OrderLine> lines) async {
    placed.add(lines);
    return Ok(Order(id: placed.length, lines: lines, status: OrderStatus.pending, placedAt: DateTime(2026, 11, 22, 10)));
  }

  @override
  Future<List<Order>> history() async => [];
}
"""

FILES = {
    "lib/core/result.dart": """// {w_c_result}
sealed class Result<T, F> {
  const Result();
}

final class Ok<T, F> extends Result<T, F> {
  const Ok(this.value);
  final T value;
}

final class Err<T, F> extends Result<T, F> {
  const Err(this.failure);
  final F failure;
}
""",
    D + "money.dart": """// {w_c_money}
class Money implements Comparable<Money> {
  const Money(this.pounds);

  final int pounds;

  Money operator +(Money other) => Money(pounds + other.pounds);
  Money operator *(int times) => Money(pounds * times);

  @override
  int compareTo(Money other) => pounds.compareTo(other.pounds);

  @override
  bool operator ==(Object other) => other is Money && other.pounds == pounds;

  @override
  int get hashCode => pounds.hashCode;
}
""",
    D + "order.dart": """import 'money.dart';

class MenuItem {
  const MenuItem(this.id, this.price);

  final String id;
  final Money price;
}

const menu = [MenuItem('latte', Money(45)), MenuItem('tea', Money(25)), MenuItem('cake', Money(60))];

class OrderLine {
  const OrderLine(this.item, this.quantity);

  final MenuItem item;
  final int quantity;

  Money get total => item.price * quantity;
}

enum OrderStatus { pending, preparing, ready, cancelled }

// {w_c_entity}
class Order {
  const Order({required this.id, required this.lines, required this.status, required this.placedAt});

  final int id;
  final List<OrderLine> lines;
  final OrderStatus status;
  final DateTime placedAt;

  Money get total => lines.fold(const Money(0), (sum, line) => sum + line.total);
  int get items => lines.fold(0, (sum, line) => sum + line.quantity);
}
""",
    D + "failures.dart": """// {w_c_failures}
sealed class OrderFailure {
  const OrderFailure();
}

final class EmptyOrder extends OrderFailure {
  const EmptyOrder();
}

final class TooLarge extends OrderFailure {
  const TooLarge(this.max);
  final int max;
}

final class Closed extends OrderFailure {
  const Closed();
}

final class NetworkFailure extends OrderFailure {
  const NetworkFailure();
}
""",
    D + "orders_repository.dart": """import '../../../core/result.dart';
import 'failures.dart';
import 'order.dart';

// {w_c_port}
abstract interface class OrdersRepository {
  Future<Result<Order, OrderFailure>> place(List<OrderLine> lines);
  Future<List<Order>> history();
}
""",
    D + "place_order.dart": """import '../../../core/result.dart';
import 'failures.dart';
import 'order.dart';
import 'orders_repository.dart';

// {w_c_usecase}
class PlaceOrder {
  PlaceOrder(this.repository, {DateTime Function()? clock}) : clock = clock ?? DateTime.now;

  final OrdersRepository repository;
  final DateTime Function() clock;

  static const maxItems = 20;

  Future<Result<Order, OrderFailure>> call(List<OrderLine> lines) async {
    // {w_c_rules}
    final items = lines.fold(0, (sum, line) => sum + line.quantity);
    if (items == 0) {
      return const Err(EmptyOrder());
    }
    if (items > maxItems) {
      return const Err(TooLarge(maxItems));
    }
    final hour = clock().hour;
    if (hour < 8 || hour >= 22) {
      return const Err(Closed());
    }
    return repository.place(lines);
  }
}
""",
    DATA + "order_dto.dart": """// {w_c_dto}
class OrderDto {
  const OrderDto({required this.id, required this.items, required this.status, required this.placedAt});

  factory OrderDto.fromJson(Map<String, dynamic> json) => OrderDto(
    id: json['id'] as int,
    items: (json['items'] as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int)),
    status: json['status'] as String,
    placedAt: json['placed_at'] as String,
  );

  final int id;
  final Map<String, int> items;
  final String status;
  final String placedAt;
}
""",
    DATA + "orders_source.dart": """abstract interface class OrdersSource {
  Future<Map<String, dynamic>> post(Map<String, int> items);
  Future<List<Map<String, dynamic>>> list();
}

// {w_c_source}
class FakeOrdersSource implements OrdersSource {
  FakeOrdersSource({this.fails = false});

  final bool fails;
  final _orders = <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>> post(Map<String, int> items) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (fails) {
      throw Exception('connection refused');
    }
    final order = {'id': _orders.length + 1, 'items': items, 'status': 'pending', 'placed_at': '2026-11-22T10:00:00'};
    _orders.insert(0, order);
    return order;
  }

  @override
  Future<List<Map<String, dynamic>>> list() async => [..._orders];
}
""",
    DATA + "orders_repository_impl.dart": """import '../../../core/result.dart';
import '../domain/failures.dart';
import '../domain/order.dart';
import '../domain/orders_repository.dart';
import 'order_dto.dart';
import 'orders_source.dart';

// {w_c_impl}
class OrdersRepositoryImpl implements OrdersRepository {
  OrdersRepositoryImpl(this.source);

  final OrdersSource source;

  @override
  Future<Result<Order, OrderFailure>> place(List<OrderLine> lines) async {
    try {
      final json = await source.post({for (final l in lines) l.item.id: l.quantity});
      return Ok(_toOrder(OrderDto.fromJson(json)));
    } catch (_) {
      // {w_c_catch}
      return const Err(NetworkFailure());
    }
  }

  @override
  Future<List<Order>> history() async => [for (final json in await source.list()) _toOrder(OrderDto.fromJson(json))];

  Order _toOrder(OrderDto dto) => Order(
    id: dto.id,
    lines: [
      for (final MapEntry(:key, :value) in dto.items.entries) OrderLine(menu.firstWhere((m) => m.id == key), value),
    ],
    status: OrderStatus.values.byName(dto.status),
    placedAt: DateTime.parse(dto.placedAt),
  );
}
""",
    P + "orders_controller.dart": """import 'package:material_ui/material_ui.dart';

import '../../../core/result.dart';
import '../domain/failures.dart';
import '../domain/order.dart';
import '../domain/orders_repository.dart';
import '../domain/place_order.dart';

// {w_c_controller}
class OrdersController extends ChangeNotifier {
  OrdersController(this.placeOrder, this.repository);

  final PlaceOrder placeOrder;
  final OrdersRepository repository;

  final basket = <MenuItem, int>{};
  var history = <Order>[];
  var placing = false;
  String? message;

  void add(MenuItem item) {
    basket[item] = (basket[item] ?? 0) + 1;
    message = null;
    notifyListeners();
  }

  Future<void> place() async {
    placing = true;
    notifyListeners();
    final result = await placeOrder([for (final e in basket.entries) OrderLine(e.key, e.value)]);
    switch (result) {
      case Ok(:final value):
        basket.clear();
        message = '{w_m_placed}: {w_order_n} ${value.id}';
        history = await repository.history();
      case Err(:final failure):
        message = describe(failure);
    }
    placing = false;
    notifyListeners();
  }

  // {w_c_words}
  static String describe(OrderFailure failure) => switch (failure) {
    EmptyOrder() => '{w_m_empty}',
    TooLarge() => '{w_m_large}',
    Closed() => '{w_m_closed}',
    NetworkFailure() => '{w_m_network}',
  };
}
""",
    P + "orders_page.dart": """import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../domain/order.dart';
import 'orders_controller.dart';

const names = {'latte': '{w_latte}', 'tea': '{w_tea}', 'cake': '{w_cake}'};

// {w_c_status}
const statusNames = {
  OrderStatus.pending: '{w_pending}',
  OrderStatus.preparing: '{w_preparing}',
  OrderStatus.ready: '{w_ready}',
  OrderStatus.cancelled: '{w_cancelled}',
};

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<OrdersController>();
    final count = c.basket.values.fold(0, (a, b) => a + b);
    return Scaffold(
      appBar: AppBar(title: const Text('{w_title}')),
      body: ListView(
        children: [
          for (final item in menu)
            ListTile(
              title: Text(names[item.id]!),
              subtitle: Text('${item.price.pounds} {w_egp}'),
              leading: CircleAvatar(child: Text('${c.basket[item] ?? 0}')),
              trailing: IconButton(
                tooltip: '{w_add} ${names[item.id]}',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => context.read<OrdersController>().add(item),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: c.placing ? null : context.read<OrdersController>().place,
              child: Text(c.placing ? '{w_placing}' : '{w_place} · {w_basket}: $count'),
            ),
          ),
          if (c.message case final message?)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(message))),
            ),
          ListTile(title: Text('{w_history}', style: Theme.of(context).textTheme.titleMedium)),
          if (c.history.isEmpty) const ListTile(title: Text('{w_nothing}')),
          for (final order in c.history)
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text('{w_order_n} ${order.id} · ${order.total.pounds} {w_egp}'),
              subtitle: Text('{w_items}: ${order.items} · ${statusNames[order.status]}'),
            ),
        ],
      ),
    );
  }
}
""",
    "lib/orders_app.dart": APP % ("{w_c_root}", "FakeOrdersSource()", "() => DateTime(2026, 11, 22, 10)"),
    "lib/orders_closed.dart": APP % ("{w_c_closed}", "FakeOrdersSource()", "() => DateTime(2026, 11, 22, 23)"),
    "lib/orders_offline.dart": APP % ("{w_c_offline}", "FakeOrdersSource(fails: true)", "() => DateTime(2026, 11, 22, 10)"),
    "test/domain/place_order_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/core/result.dart';
import 'package:bit_app/features/orders/domain/failures.dart';
import 'package:bit_app/features/orders/domain/order.dart';
import 'package:bit_app/features/orders/domain/orders_repository.dart';
import 'package:bit_app/features/orders/domain/place_order.dart';

""" + FAKE_REPO + """
void main() {
  test('{w_t_place}', () async {
    final repo = FakeRepository();
    var hour = 10;
    final place = PlaceOrder(repo, clock: () => DateTime(2026, 11, 22, hour));
    final latte = OrderLine(menu.first, 2);

    expect(await place([]), isA<Err<Order, OrderFailure>>().having((e) => e.failure, 'failure', isA<EmptyOrder>()));
    expect((await place([OrderLine(menu.first, 21)]) as Err).failure, isA<TooLarge>());
    hour = 23;
    expect((await place([latte]) as Err).failure, isA<Closed>());
    expect(repo.placed, isEmpty);

    hour = 10;
    final ok = await place([latte]) as Ok<Order, OrderFailure>;
    expect(ok.value.total.pounds, 90);
    expect(repo.placed, hasLength(1));
  });
}
""",
    "test/data/orders_repository_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/core/result.dart';
import 'package:bit_app/features/orders/data/orders_repository_impl.dart';
import 'package:bit_app/features/orders/data/orders_source.dart';
import 'package:bit_app/features/orders/domain/failures.dart';
import 'package:bit_app/features/orders/domain/order.dart';

void main() {
  test('{w_t_repo}', () async {
    final repo = OrdersRepositoryImpl(FakeOrdersSource());
    final placed = await repo.place([OrderLine(menu[0], 2), OrderLine(menu[2], 1)]) as Ok;
    final order = placed.value as Order;
    expect(order.total.pounds, 150);
    expect(order.status, OrderStatus.pending);
    expect((await repo.history()).single.items, 3);

    final offline = OrdersRepositoryImpl(FakeOrdersSource(fails: true));
    expect((await offline.place([OrderLine(menu[0], 1)]) as Err).failure, isA<NetworkFailure>());
  });
}
""",
    "test/presentation/orders_page_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:bit_app/features/orders/data/orders_repository_impl.dart';
import 'package:bit_app/features/orders/data/orders_source.dart';
import 'package:bit_app/features/orders/domain/place_order.dart';
import 'package:bit_app/features/orders/presentation/orders_controller.dart';
import 'package:bit_app/features/orders/presentation/orders_page.dart';

Widget app({required int hour}) {
  final repo = OrdersRepositoryImpl(FakeOrdersSource());
  return ChangeNotifierProvider(
    // {w_c_testkey}
    key: ValueKey(hour),
    create: (context) => OrdersController(PlaceOrder(repo, clock: () => DateTime(2026, 11, 22, hour)), repo),
    child: const MaterialApp(home: OrdersPage()),
  );
}

void main() {
  testWidgets('{w_t_page}', (tester) async {
    await tester.pumpWidget(app(hour: 10));
    await tester.tap(find.byTooltip('{w_add} {w_latte}'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('{w_order_n} 1 · 45 {w_egp}'), findsOneWidget);

    await tester.pumpWidget(app(hour: 23));
    await tester.tap(find.byTooltip('{w_add} {w_latte}'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('{w_m_closed}'), findsOneWidget);
  });
}
""",
    "test/architecture_test.dart": """import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// {w_c_forbidden}
const forbidden = ['package:flutter/', 'package:material_ui/', 'package:provider/', 'package:http/', '/data/', '/presentation/'];

/// Every import in a domain folder that breaks the rule, as "file: import".
List<String> violations(String root) => [
  for (final file in Directory(root).listSync(recursive: true).whereType<File>())
    if (file.path.contains('/domain/') && file.path.endsWith('.dart'))
      for (final line in file.readAsLinesSync())
        if (line.startsWith('import ') && forbidden.any(line.contains)) '${file.path}: $line',
];

void main() {
  test('{w_t_arch}', () {
    // {w_c_rule}
    expect(violations('lib/features'), isEmpty);
  });
}
""",
    "test/architecture_bad_test.dart": """import 'package:flutter_test/flutter_test.dart';

import 'architecture_test.dart' as rules;

void main() {
  test('{w_t_arch_bad}', () {
    expect(rules.violations('test/fixtures'), isEmpty);
  });
}
""",
    "test/fixtures/orders/domain/status_color.dart": """import 'package:material_ui/material_ui.dart';

import 'order.dart';

Color statusColor(OrderStatus s) => s == OrderStatus.ready ? Colors.green : Colors.grey;
""",
    "test/fixtures/orders/domain/order.dart": """enum OrderStatus { pending, ready }
""",
    # Projects
    D + "cancel_order.dart": """import '../../../core/result.dart';
import 'order.dart';

sealed class CancelFailure {
  const CancelFailure();
}

final class NotPending extends CancelFailure {
  const NotPending();
}

final class TooLate extends CancelFailure {
  const TooLate();
}

// {w_c_cancel}
class CancelOrder {
  CancelOrder({DateTime Function()? clock}) : clock = clock ?? DateTime.now;

  final DateTime Function() clock;

  static const window = Duration(minutes: 5);

  Result<Order, CancelFailure> call(Order order) {
    if (order.status != OrderStatus.pending) {
      return const Err(NotPending());
    }
    if (clock().difference(order.placedAt) > window) {
      return const Err(TooLate());
    }
    return Ok(Order(id: order.id, lines: order.lines, status: OrderStatus.cancelled, placedAt: order.placedAt));
  }
}
""",
    "test/domain/cancel_order_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/core/result.dart';
import 'package:bit_app/features/orders/domain/cancel_order.dart';
import 'package:bit_app/features/orders/domain/order.dart';

void main() {
  test('{w_t_cancel}', () {
    final placed = DateTime(2026, 11, 22, 10);
    Order order(OrderStatus s) => Order(id: 1, lines: [OrderLine(menu.first, 1)], status: s, placedAt: placed);
    CancelOrder at(int minutes) => CancelOrder(clock: () => placed.add(Duration(minutes: minutes)));

    expect((at(2)(order(OrderStatus.pending)) as Ok).value, isA<Order>().having((o) => o.status, 'status', OrderStatus.cancelled));
    expect((at(2)(order(OrderStatus.ready)) as Err).failure, isA<NotPending>());
    expect((at(5)(order(OrderStatus.pending)) as Ok).value, isA<Order>());
    expect((at(6)(order(OrderStatus.pending)) as Err).failure, isA<TooLate>());
  });
}
""",
    DATA + "http_orders_source.dart": """import 'dart:convert';

import 'package:http/http.dart' as http;

import 'orders_source.dart';

// {w_c_http}
class HttpOrdersSource implements OrdersSource {
  HttpOrdersSource(this.client, {this.base = 'https://api.example.com'});

  final http.Client client;
  final String base;

  @override
  Future<Map<String, dynamic>> post(Map<String, int> items) async {
    final response = await client
        .post(Uri.parse('$base/orders'), headers: {'content-type': 'application/json'}, body: jsonEncode({'items': items}))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 201) {
      throw http.ClientException('HTTP ${response.statusCode}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> list() async {
    final response = await client.get(Uri.parse('$base/orders'));
    return (jsonDecode(utf8.decode(response.bodyBytes)) as List).cast<Map<String, dynamic>>();
  }
}
""",
    "test/data/http_orders_source_test.dart": """import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bit_app/core/result.dart';
import 'package:bit_app/features/orders/data/http_orders_source.dart';
import 'package:bit_app/features/orders/data/orders_repository_impl.dart';
import 'package:bit_app/features/orders/domain/failures.dart';
import 'package:bit_app/features/orders/domain/order.dart';

void main() {
  test('{w_t_http}', () async {
    final server = MockClient((request) async {
      final items = (jsonDecode(request.body) as Map)['items'] as Map;
      if (items.containsKey('cake')) {
        return http.Response('{"error": "sold out"}', 409);
      }
      return http.Response(
        jsonEncode({'id': 7, 'items': items, 'status': 'pending', 'placed_at': '2026-11-22T10:00:00'}),
        201,
      );
    });
    final repo = OrdersRepositoryImpl(HttpOrdersSource(server));

    final ok = await repo.place([OrderLine(menu[1], 3)]) as Ok;
    expect((ok.value as Order).total.pounds, 75);
    expect((await repo.place([OrderLine(menu[2], 1)]) as Err).failure, isA<NetworkFailure>());
  });
}
""",
    "test/features_test.dart": """import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// {w_c_features}
List<String> crossFeature(String root) {
  final found = <String>[];
  for (final file in Directory(root).listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
    final feature = RegExp(r'features/(\\w+)/').firstMatch(file.path)!.group(1);
    for (final line in file.readAsLinesSync().where((l) => l.startsWith('import '))) {
      final other = RegExp(r'features/(\\w+)/(\\w+)/').firstMatch(line) ?? RegExp(r"'\\.\\./\\.\\./(\\w+)/(\\w+)/").firstMatch(line);
      if (other != null && other.group(1) != feature && other.group(2) != 'domain') {
        found.add('${file.path}: $line');
      }
    }
  }
  return found;
}

void main() {
  test('{w_t_features}', () {
    expect(crossFeature('lib/features'), isEmpty);
    expect(crossFeature('test/fixtures_features'), hasLength(1));
  });
}
""",
    "test/fixtures_features/features/orders/domain/order.dart": """enum OrderStatus { pending, ready }
""",
    "test/fixtures_features/features/orders/presentation/orders_controller.dart": """class OrdersController {}
""",
    "test/fixtures_features/features/menu/presentation/menu_page.dart": """import '../../orders/domain/order.dart';
import '../../orders/presentation/orders_controller.dart';

const uses = [OrderStatus, OrdersController];
""",
}


def failure(lines):
    """The failing run, without the stack trace."""
    end = next(i for i, l in enumerate(lines) if l.strip().startswith("package:matcher"))
    return [l for l in lines[:end] if l.strip()]


SHOTS = [
    ("placed.png", "lib/orders_app.dart",
     "button={w_add} {w_latte}|button={w_add} {w_latte}|button={w_add} {w_cake}|button={w_place}|wait=1500"),
    ("closed.png", "lib/orders_closed.dart", "button={w_add} {w_latte}|button={w_place}|wait=1000"),
    ("offline.png", "lib/orders_offline.dart", "button={w_add} {w_tea}|button={w_place}|wait=1500"),
]

TESTS = [
    ("place-order-test.sh", "test/domain/place_order_test.dart"),
    ("repository-test.sh", "test/data/orders_repository_test.dart"),
    ("page-test.sh", "test/presentation/orders_page_test.dart"),
    ("architecture-test.sh", "test/architecture_test.dart"),
    ("architecture-bad.sh", "test/architecture_bad_test.dart", failure),
    ("projects/cancel-test.sh", "test/domain/cancel_order_test.dart"),
    ("projects/http-test.sh", "test/data/http_orders_source_test.dart"),
    ("projects/features-test.sh", "test/features_test.dart"),
]


def main():
    flutter_gallery(HERE, T, FILES, SHOTS, TESTS, packages=["provider", "http"])


if __name__ == "__main__":
    main()
