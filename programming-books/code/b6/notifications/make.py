"""Writes the examples of Book 6, chapter "Push Notifications and Background Work", in English and Arabic.
This machine has no phone and the book has no Firebase project, so the chapter is honest about what runs:
the messages, the routing, the permission flow and the background job are plain Dart and widgets, tested
here with fakes; the Firebase, local-notification and WorkManager code is compiled into a real Android
build (which first fails, as it does for every app that adds these plugins, until it is fixed), and the
permissions the plugins add are read from that APK.
Run: python3 make.py   (needs Flutter 3.50.1 with the Android SDK, Node.js and Playwright's Chromium)
"""
import shutil
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent.parent / "b5"))
from kit import WORK, Session, flutter_gallery, write  # noqa: E402

T = {
    "en": dict(
        w_rtl="",
        w_menu="Menu", w_order_latte="Order a latte", w_ordered="Ordered! We will tell you when it is ready.",
        w_ready="Your latte is ready", w_ready_body="Order 42 is waiting at the counter.", w_view="View",
        w_order="Order", w_at_counter="Ready at the counter", w_on_its_way="Being prepared",
        w_ask_title="Know when your order is ready?", w_ask_body="We only send order updates, never ads at night.",
        w_turn_on="Turn on", w_not_now="Not now", w_in_settings="Notifications are off. You can turn them on in Settings.",
        w_channel="Orders", w_channel_d="When your order is ready",
        w_c_types="What the server may send. Anything else is ignored, not guessed.",
        w_c_route="A message knows where it leads; the app decides when to go there.",
        w_c_port="The app depends on this, never on Firebase directly.",
        w_c_states="Three moments: open on screen, tapped from the tray, or the tap that started the app.",
        w_c_fg="In the foreground the system shows nothing: the app shows its own banner.",
        w_c_ask="Ask after the first order, when the reason is obvious, not at the first launch.",
        w_c_demo="For the demo app: a message arrives a moment after the app opens.",
        w_c_job="The background job: plain Dart, safe to run twice, and quick.",
        w_c_seen="Notify once per order, even if the job runs again.",
        w_c_entry="Must be a top-level function, kept by the compiler for the system to call.",
        w_c_minimum="Android runs periodic work at most every 15 minutes, when the system chooses.",
        w_c_quiet="Promotions wait for the morning; order updates never wait.",
        w_c_budget="Stop early and ask to be run again, rather than be killed half way.",
        w_t_parse="push messages become routes, or nothing",
        w_t_fg="a message in the foreground shows a banner that opens the order",
        w_t_opened="a tapped notification opens its order", w_t_initial="a notification that started the app opens its order",
        w_t_sync="the background job notifies once, even when run twice",
        w_t_quiet="quiet hours", w_t_ask="the permission card appears after the first order, and only once",
        w_t_budget="a slow network: stop early and retry later",
    ),
    "ar": dict(
        w_rtl="// من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.\n"
              "builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),\n",
        w_menu="القائمة", w_order_latte="اطلب لاتيه", w_ordered="تم الطلب! سنخبرك حين يجهز.",
        w_ready="اللاتيه جاهز", w_ready_body="الطلب 42 ينتظرك عند المنضدة.", w_view="اعرض",
        w_order="الطلب", w_at_counter="جاهز عند المنضدة", w_on_its_way="قيد التحضير",
        w_ask_title="تريد أن تعرف حين يجهز طلبك؟", w_ask_body="نرسل تحديثات الطلب فقط، ولا إعلانات ليلاً.",
        w_turn_on="فعّل", w_not_now="ليس الآن", w_in_settings="الإشعارات مطفأة. يمكنك تفعيلها من الإعدادات.",
        w_channel="الطلبات", w_channel_d="حين يجهز طلبك",
        w_c_types="ما قد يرسله الخادم. وأي شيء آخر يُتجاهل، ولا يُخمَّن.",
        w_c_route="الرسالة تعرف إلى أين تقود؛ والتطبيق يقرر متى يذهب.",
        w_c_port="التطبيق يعتمد على هذه، لا على Firebase مباشرة.",
        w_c_states="ثلاث لحظات: مفتوح على الشاشة، أو ضُغط من الدرج، أو الضغطة التي شغّلت التطبيق.",
        w_c_fg="في المقدمة لا يعرض النظام شيئاً: التطبيق يعرض شريطه الخاص.",
        w_c_ask="اسأل بعد أول طلب، حين يكون السبب واضحاً، لا عند أول فتح.",
        w_c_demo="لتطبيق العرض: رسالة تصل بعد لحظة من فتح التطبيق.",
        w_c_job="مهمة الخلفية: Dart خالصة، آمنة إن جرت مرتين، وسريعة.",
        w_c_seen="أشعر مرة واحدة لكل طلب، حتى لو جرت المهمة مرة أخرى.",
        w_c_entry="يجب أن تكون دالة في أعلى الملف، يُبقيها المترجم ليناديها النظام.",
        w_c_minimum="Android يشغّل العمل الدوري كل 15 دقيقة على الأكثر، حين يختار النظام.",
        w_c_quiet="العروض تنتظر الصباح؛ وتحديثات الطلب لا تنتظر أبداً.",
        w_c_budget="توقف مبكراً واطلب أن تُشغَّل مرة أخرى، بدل أن تُقتل في المنتصف.",
        w_t_parse="رسائل الدفع تصير مسارات، أو لا شيء",
        w_t_fg="رسالة في المقدمة تعرض شريطاً يفتح الطلب",
        w_t_opened="إشعار مضغوط يفتح طلبه", w_t_initial="إشعار شغّل التطبيق يفتح طلبه",
        w_t_sync="مهمة الخلفية تُشعر مرة واحدة، حتى لو جرت مرتين",
        w_t_quiet="ساعات الهدوء", w_t_ask="بطاقة الإذن تظهر بعد أول طلب، ومرة واحدة",
        w_t_budget="شبكة بطيئة: توقف مبكراً وأعد المحاولة لاحقاً",
    ),
}

FILES = {
    "lib/push/message.dart": """// {w_c_types}
enum PushKind { orderReady, orderUpdate, promo }

class PushMessage {
  const PushMessage(this.kind, {this.orderId, this.title, this.body});

  final PushKind kind;
  final String? orderId;
  final String? title;
  final String? body;

  // FCM delivers a message's data as a map of strings.
  static PushMessage? fromData(Map<String, Object?> data) {
    final kind = switch (data['type']) {
      'order_ready' => PushKind.orderReady,
      'order_update' => PushKind.orderUpdate,
      'promo' => PushKind.promo,
      _ => null,
    };
    if (kind == null) {
      return null;
    }
    final orderId = data['order_id'] as String?;
    if (kind != PushKind.promo && (orderId == null || !RegExp(r'^\\d+$').hasMatch(orderId))) {
      return null;
    }
    return PushMessage(kind, orderId: orderId, title: data['title'] as String?, body: data['body'] as String?);
  }

  // {w_c_route}
  String get route => switch (kind) {
    PushKind.orderReady || PushKind.orderUpdate => '/orders/$orderId',
    PushKind.promo => '/',
  };
}
""",
    "lib/push/push_source.dart": """import 'message.dart';

enum PermissionState { unknown, granted, denied }

// {w_c_port}
abstract interface class PushSource {
  // {w_c_states}
  Stream<PushMessage> get foreground;
  Stream<PushMessage> get opened;
  Future<PushMessage?> initial();

  Future<PermissionState> permission();
  Future<PermissionState> request();
}
""",
    "lib/push/firebase_source.dart": """import 'package:firebase_messaging/firebase_messaging.dart';

import 'message.dart';
import 'push_source.dart';

class FirebasePushSource implements PushSource {
  final _messaging = FirebaseMessaging.instance;

  static PushMessage? _read(RemoteMessage message) => PushMessage.fromData(message.data);

  @override
  Stream<PushMessage> get foreground => FirebaseMessaging.onMessage.map(_read).where((m) => m != null).cast();

  @override
  Stream<PushMessage> get opened => FirebaseMessaging.onMessageOpenedApp.map(_read).where((m) => m != null).cast();

  @override
  Future<PushMessage?> initial() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _read(message);
  }

  static PermissionState _state(NotificationSettings settings) => switch (settings.authorizationStatus) {
    AuthorizationStatus.authorized || AuthorizationStatus.provisional => PermissionState.granted,
    AuthorizationStatus.denied || AuthorizationStatus.deniedPermanently => PermissionState.denied,
    AuthorizationStatus.notDetermined => PermissionState.unknown,
  };

  @override
  Future<PermissionState> permission() async => _state(await _messaging.getNotificationSettings());

  @override
  Future<PermissionState> request() async => _state(await _messaging.requestPermission());
}
""",
    "lib/cafe.dart": """import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'push/message.dart';
import 'push/push_source.dart';

class CafeApp extends StatefulWidget {
  const CafeApp({super.key, required this.push});

  final PushSource push;

  @override
  State<CafeApp> createState() => _CafeAppState();
}

class _CafeAppState extends State<CafeApp> {
  final messenger = GlobalKey<ScaffoldMessengerState>();
  late final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => HomePage(push: widget.push),
        routes: [GoRoute(path: 'orders/:id', builder: (context, state) => OrderPage(id: state.pathParameters['id']!))],
      ),
    ],
  );
  final subscriptions = <StreamSubscription<PushMessage>>[];

  @override
  void initState() {
    super.initState();
    subscriptions
      ..add(widget.push.foreground.listen(showBanner))
      ..add(widget.push.opened.listen((message) => router.go(message.route)));
    widget.push.initial().then((message) {
      if (message != null) {
        router.go(message.route);
      }
    });
  }

  // {w_c_fg}
  void showBanner(PushMessage message) {
    messenger.currentState?.showSnackBar(
      SnackBar(
        content: Text(message.title ?? ''),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(label: '{w_view}', onPressed: () => router.go(message.route)),
      ),
    );
  }

  @override
  void dispose() {
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      {w_rtl}
      scaffoldMessengerKey: messenger,
      theme: ThemeData(colorSchemeSeed: Colors.brown),
      routerConfig: router,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.push});

  final PushSource push;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var ordered = false;
  var asking = false;
  var denied = false;

  Future<void> order() async {
    setState(() => ordered = true);
    // {w_c_ask}
    if (await widget.push.permission() == PermissionState.unknown) {
      setState(() => asking = true);
    }
  }

  Future<void> turnOn() async {
    final answer = await widget.push.request();
    setState(() {
      asking = false;
      denied = answer == PermissionState.denied;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{w_menu}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(onPressed: ordered ? null : order, icon: const Icon(Icons.local_cafe), label: const Text('{w_order_latte}')),
          if (ordered) const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('{w_ordered}')),
          if (asking) PermissionCard(onTurnOn: turnOn, onNotNow: () => setState(() => asking = false)),
          if (denied) const Text('{w_in_settings}'),
        ],
      ),
    );
  }
}

class PermissionCard extends StatelessWidget {
  const PermissionCard({super.key, required this.onTurnOn, required this.onNotNow});

  final VoidCallback onTurnOn;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text('{w_ask_title}', style: Theme.of(context).textTheme.titleMedium),
            const Text('{w_ask_body}'),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onNotNow, child: const Text('{w_not_now}')),
                FilledButton(onPressed: onTurnOn, child: const Text('{w_turn_on}')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OrderPage extends StatelessWidget {
  const OrderPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('{w_order} $id')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [Icon(Icons.check_circle, size: 96), Text('{w_at_counter}')],
        ),
      ),
    );
  }
}
""",
    "lib/demo_push.dart": """import 'dart:async';

import 'push/message.dart';
import 'push/push_source.dart';

// {w_c_demo}
class DemoPush implements PushSource {
  DemoPush({this.state = PermissionState.unknown, this.answer = PermissionState.granted});

  PermissionState state;
  final PermissionState answer;
  final foregroundMessages = StreamController<PushMessage>.broadcast();
  final openedMessages = StreamController<PushMessage>.broadcast();
  PushMessage? started;
  var requests = 0;

  @override
  Stream<PushMessage> get foreground => foregroundMessages.stream;

  @override
  Stream<PushMessage> get opened => openedMessages.stream;

  @override
  Future<PushMessage?> initial() async => started;

  @override
  Future<PermissionState> permission() async => state;

  @override
  Future<PermissionState> request() async {
    requests++;
    return state = answer;
  }
}
""",
    "lib/demo.dart": """import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'cafe.dart';
import 'demo_push.dart';
import 'push/message.dart';

void main() {
  final push = DemoPush();
  runApp(CafeApp(push: push));
  Timer(const Duration(seconds: 1), () {
    push.foregroundMessages.add(const PushMessage(PushKind.orderReady, orderId: '42', title: '{w_ready}', body: '{w_ready_body}'));
  });
}
""",
    "lib/background/orders_api.dart": """class Order {
  const Order(this.id, this.ready);

  final String id;
  final bool ready;
}

abstract interface class OrdersApi {
  Future<List<Order>> mine();
}

abstract interface class Seen {
  Future<bool> contains(String id);
  Future<void> add(String id);
}

abstract interface class Notify {
  Future<void> orderReady(String id);
}
""",
    "lib/background/sync.dart": """import 'orders_api.dart';

// {w_c_job}
Future<int> syncOrders(OrdersApi api, Seen seen, Notify notify) async {
  var sent = 0;
  for (final order in await api.mine()) {
    // {w_c_seen}
    if (order.ready && !await seen.contains(order.id)) {
      await notify.orderReady(order.id);
      await seen.add(order.id);
      sent++;
    }
  }
  return sent;
}
""",
    "lib/background/dispatcher.dart": """import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:material_ui/material_ui.dart';
import 'package:workmanager/workmanager.dart';

import 'orders_api.dart';

// {w_c_entry}
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, input) async {
    // A real app would build its OrdersApi and Seen here, from its own HTTP client and storage,
    // then: return await syncOrders(api, seen, LocalNotify()) >= 0;
    return true;
  });
}

Future<void> scheduleSync() async {
  await Workmanager().initialize(callbackDispatcher);
  // {w_c_minimum}
  await Workmanager().registerPeriodicTask(
    'orders-sync',
    'syncOrders',
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}

class LocalNotify implements Notify {
  final _plugin = FlutterLocalNotificationsPlugin();

  @override
  Future<void> orderReady(String id) async {
    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    );
    await _plugin.show(
      id: int.parse(id),
      title: '{w_ready}',
      body: '{w_ready_body}',
      payload: '/orders/$id',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails('orders', '{w_channel}', channelDescription: '{w_channel_d}', importance: Importance.high),
      ),
    );
    debugPrint('notified order $id');
  }
}
""",
    "lib/main_firebase.dart": """import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';

import 'background/dispatcher.dart';
import 'cafe.dart';
import 'push/firebase_source.dart';

// The real entry point, for Android and iOS. It needs the project's Firebase configuration (see the text).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await scheduleSync();
  runApp(CafeApp(push: FirebasePushSource()));
}
""",
    "test/message_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/push/message.dart';

void main() {
  test('{w_t_parse}', () {
    final cases = <Map<String, Object?>>[
      {'type': 'order_ready', 'order_id': '42'},
      {'type': 'order_update', 'order_id': '7'},
      {'type': 'promo'},
      {'type': 'order_ready'},
      {'type': 'order_ready', 'order_id': '../admin'},
      {'type': 'unknown', 'order_id': '42'},
    ];
    for (final data in cases) {
      debugPrint('${data.toString().padRight(44)} -> ${PushMessage.fromData(data)?.route ?? 'ignored'}');
    }
  });
}
""",
    "test/app_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/cafe.dart';
import 'package:bit_app/demo_push.dart';
import 'package:bit_app/push/message.dart';

const ready = PushMessage(PushKind.orderReady, orderId: '42', title: 'Your latte is ready');

void main() {
  testWidgets('{w_t_fg}', (tester) async {
    final push = DemoPush();
    await tester.pumpWidget(CafeApp(push: push));
    push.foregroundMessages.add(ready);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    expect(find.text('Your latte is ready'), findsOneWidget);
    await tester.tap(find.text('{w_view}'));
    await tester.pumpAndSettle();
    expect(find.text('{w_order} 42'), findsOneWidget);
  });

  testWidgets('{w_t_opened}', (tester) async {
    final push = DemoPush();
    await tester.pumpWidget(CafeApp(push: push));
    push.openedMessages.add(ready);
    await tester.pumpAndSettle();
    expect(find.text('{w_order} 42'), findsOneWidget);
  });

  testWidgets('{w_t_initial}', (tester) async {
    final push = DemoPush()..started = ready;
    await tester.pumpWidget(CafeApp(push: push));
    await tester.pumpAndSettle();
    expect(find.text('{w_order} 42'), findsOneWidget);
  });
}
""",
    "test/sync_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/background/orders_api.dart';
import 'package:bit_app/background/sync.dart';

class FakeApi implements OrdersApi {
  @override
  Future<List<Order>> mine() async => const [Order('41', true), Order('42', true), Order('43', false)];
}

class MemorySeen implements Seen {
  final ids = <String>{};

  @override
  Future<bool> contains(String id) async => ids.contains(id);

  @override
  Future<void> add(String id) async => ids.add(id);
}

class Recorded implements Notify {
  final sent = <String>[];

  @override
  Future<void> orderReady(String id) async => sent.add(id);
}

void main() {
  test('{w_t_sync}', () async {
    final seen = MemorySeen();
    final notify = Recorded();
    final first = await syncOrders(FakeApi(), seen, notify);
    final second = await syncOrders(FakeApi(), seen, notify);
    expect(notify.sent, ['41', '42']);
    expect((first, second), (2, 0));
  });
}
""",
    # Projects
    "lib/quiet.dart": """import 'push/message.dart';

// {w_c_quiet}
bool showNow(PushMessage message, DateTime localTime) {
  if (message.kind != PushKind.promo) {
    return true;
  }
  return localTime.hour >= 8 && localTime.hour < 22;
}
""",
    "test/quiet_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/push/message.dart';
import 'package:bit_app/quiet.dart';

void main() {
  group('{w_t_quiet}', () {
    const promo = PushMessage(PushKind.promo);
    const ready = PushMessage(PushKind.orderReady, orderId: '42');
    final cases = [
      (promo, 7, 59, false),
      (promo, 8, 0, true),
      (promo, 21, 59, true),
      (promo, 22, 0, false),
      (ready, 23, 30, true),
    ];
    for (final (message, hour, minute, expected) in cases) {
      final at = DateTime(2026, 11, 23, hour, minute);
      final name = '${message.kind.name} at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      test('$name: ${expected ? 'show' : 'wait'}', () => expect(showNow(message, at), expected));
    }
  });
}
""",
    "test/permission_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/cafe.dart';
import 'package:bit_app/demo_push.dart';
import 'package:bit_app/push/push_source.dart';

void main() {
  testWidgets('{w_t_ask}', (tester) async {
    final push = DemoPush(answer: PermissionState.denied);
    await tester.pumpWidget(CafeApp(push: push));
    await tester.pumpAndSettle();
    expect(find.byType(PermissionCard), findsNothing);

    await tester.tap(find.text('{w_order_latte}'));
    await tester.pumpAndSettle();
    expect(find.byType(PermissionCard), findsOneWidget);

    await tester.tap(find.text('{w_turn_on}'));
    await tester.pumpAndSettle();
    expect(push.requests, 1);
    expect(find.byType(PermissionCard), findsNothing);
    expect(find.text('{w_in_settings}'), findsOneWidget);
  });
}
""",
    "lib/background/budget.dart": """import 'dart:async';

import 'orders_api.dart';
import 'sync.dart';

enum Outcome { done, retry }

// {w_c_budget}
Future<Outcome> syncWithin(Duration budget, OrdersApi api, Seen seen, Notify notify) async {
  try {
    await syncOrders(api, seen, notify).timeout(budget);
    return Outcome.done;
  } on TimeoutException {
    return Outcome.retry;
  }
}
""",
    "test/budget_test.dart": """import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/background/budget.dart';
import 'package:bit_app/background/orders_api.dart';

class SlowApi implements OrdersApi {
  SlowApi(this.delay);

  final Duration delay;

  @override
  Future<List<Order>> mine() => Future.delayed(delay, () => const [Order('42', true)]);
}

class MemorySeen implements Seen {
  final ids = <String>{};

  @override
  Future<bool> contains(String id) async => ids.contains(id);

  @override
  Future<void> add(String id) async => ids.add(id);
}

class Recorded implements Notify {
  final sent = <String>[];

  @override
  Future<void> orderReady(String id) async => sent.add(id);
}

void main() {
  test('{w_t_budget}', () {
    fakeAsync((time) {
      final seen = MemorySeen();
      final notify = Recorded();
      Outcome? slow;
      Outcome? fast;
      syncWithin(const Duration(seconds: 20), SlowApi(const Duration(seconds: 45)), seen, notify).then((o) => slow = o);
      time.elapse(const Duration(seconds: 60));
      syncWithin(const Duration(seconds: 20), SlowApi(const Duration(seconds: 2)), seen, notify).then((o) => fast = o);
      time.elapse(const Duration(seconds: 60));
      debugPrint('network answers in 45 s: ${slow!.name}; in 2 s: ${fast!.name}; notified ${notify.sent}');
      expect((slow, fast), (Outcome.retry, Outcome.done));
    });
  });
}
""",
}

SHOTS = [
    ("banner.png", "lib/demo.dart", "wait=2000"),
    ("order.png", "lib/demo.dart", "wait=1500|button={w_view}|wait=900"),
    ("ask.png", "lib/demo.dart", "wait=12000|button={w_order_latte}|wait=900"),
]

TESTS = [
    ("message-test.sh", "test/message_test.dart"),
    ("app-test.sh", "test/app_test.dart"),
    ("sync-test.sh", "test/sync_test.dart"),
    ("projects/quiet-test.sh", "test/quiet_test.dart"),
    ("projects/permission-test.sh", "test/permission_test.dart"),
    ("projects/budget-test.sh", "test/budget_test.dart"),
]

AAPT2 = "/opt/android-sdk/build-tools/36.0.0/aapt2"


def build_failure(lines):
    """Gradle's answer is long; the book keeps what it says the plugins require."""
    keep = [l for l in lines if l.startswith("$") or "requires" in l or "is currently compiled" in l
            or "compile against version" in l or "Android APIs" in l or "for :app" in l or "BUILD FAILED" in l]
    return [l.strip() if not l.startswith("$") else l for l in keep]


def built(lines):
    return [l for l in lines if l.startswith("$") or l.startswith("✓")]


def android():
    """The real Android build, done once on the English project (the Arabic one is the same code): it fails
    as Flutter creates it, the build file is fixed, then it builds, and the APK's permissions are read."""
    project = WORK / HERE.name / "en" / "bit_app"
    gradle = project / "android" / "app" / "build.gradle.kts"
    patches = [("compileSdk = flutter.compileSdkVersion", "compileSdk = 37"),
               ("    compileOptions {\n", "    compileOptions {\n        isCoreLibraryDesugaringEnabled = true\n"),
               ("\nflutter {", '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")\n}\n\nflutter {')]
    text = gradle.read_text()
    for before, after in reversed(patches):  # as Flutter created it, if an earlier run had fixed it
        text = text.replace(after, before)
    gradle.write_text(text)
    s = Session(project)
    s.run("flutter build apk --debug -t lib/main_firebase.dart", check=False, keep=build_failure)
    s.save(HERE / "en" / "android-fail.sh")
    for before, after in patches:
        text = text.replace(before, after)
    gradle.write_text(text)
    s.run("flutter build apk --debug -t lib/main_firebase.dart", keep=built)
    s.save(HERE / "en" / "android-build.sh")
    s.run(f"{AAPT2} dump permissions build/app/outputs/flutter-apk/app-debug.apk",
          shown="aapt2 dump permissions build/app/outputs/flutter-apk/app-debug.apk")
    s.save(HERE / "en" / "permissions.sh")
    for lang in T:
        write(HERE / lang, {"android/app/build.gradle.kts": text})
        if lang != "en":
            for name in ("android-fail.sh", "android-build.sh", "permissions.sh"):
                shutil.copy(HERE / "en" / name, HERE / lang / name)


def main():
    flutter_gallery(HERE, T, FILES, SHOTS, TESTS,
                    packages=["go_router", "firebase_core", "firebase_messaging", "flutter_local_notifications",
                              "workmanager", "'dev:fake_async'"])
    android()


if __name__ == "__main__":
    main()
