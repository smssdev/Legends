"""Writes the examples of Book 6, chapter "Offline-First Apps", in English and Arabic: a local store as the source
of truth, an outbox of unsent changes, a sync engine that pushes and pulls, per-field conflict rules, and a screen
that works with the network switched off. Tests drive a fake server that can go offline, lose answers, refuse
orders, and change statuses on its own.
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
        w_orders="Orders", w_online="Online", w_offline_banner="You are offline. New orders are kept here and sent when you are back.",
        w_order_latte="Order a latte", w_order_cake="Order a cake", w_sync="Sync now", w_mark="Café: first order ready",
        w_latte="Latte", w_cake="Cherry cake", w_queued="Waiting to send", w_synced="Sent", w_failed="Not sent",
        w_new="new", w_ready="ready", w_last="Last sync",
        w_c_order="One order as this phone knows it, with how far it got in reaching the server.",
        w_c_owner="Who owns which field: the person writes the note; the café writes the status.",
        w_c_store="The source of truth for every screen. Screens watch it; they never wait for the network.",
        w_c_outbox="The outbox: every order with changes the server has not confirmed yet, oldest first.",
        w_c_emit="Every change is announced, so every screen that watches is updated at once.",
        w_c_remote="The café's server, pretended: it can go offline, lose an answer, refuse an order, and change statuses by itself.",
        w_c_idem="The order id is the idempotency key: the same order sent twice is stored once.",
        w_c_engine="Push what is waiting, then pull what changed. Stops quietly when offline; tries again next time.",
        w_c_push="Only the person's fields are sent; the answer says how new the server's copy now is.",
        w_c_refused="A refusal will not change by retrying: mark it and move on.",
        w_c_pull="Only what changed since the last sync: the cursor is the highest version seen.",
        w_c_merge="Merge field by field: the café's status always wins; the note from the server only if ours has no unsent change.",
        w_c_place="Write locally first: the order is on the screen before the network is even tried.",
        w_c_auto="If the network is there, send it now; if not, it waits in the outbox.",
        w_t_sync="orders wait offline, are sent once, and refusals are not retried",
        w_t_merge="an offline note and the new status from the café both survive",
        w_t_screen="offline, the order still appears, marked as waiting",
        w_t_pending="the badge counts what is waiting",
        w_t_auto="coming back online sends what was waiting",
        w_t_sqlite="the same sync works on SQLite",
        w_c_pending="Derived from the orders: nothing to keep in step.",
        w_c_reconnect="When the network comes back, sync without being asked.",
        w_c_sqlite="The same LocalStore, kept in SQLite: the engine and the screens do not change.",
        w_c_changes="SQLite has no stream of changes: the store announces its own writes.",
    ),
    "ar": dict(
        w_rtl="// من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.\n"
              "builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),\n",
        w_orders="الطلبات", w_online="متصل", w_offline_banner="أنت غير متصل. الطلبات الجديدة تُحفظ هنا وتُرسل حين تعود.",
        w_order_latte="اطلب لاتيه", w_order_cake="اطلب كيكة", w_sync="زامن الآن", w_mark="المقهى: أول طلب جاهز",
        w_latte="لاتيه", w_cake="كيك الكرز", w_queued="ينتظر الإرسال", w_synced="أُرسل", w_failed="لم يُرسل",
        w_new="جديد", w_ready="جاهز", w_last="آخر مزامنة",
        w_c_order="طلب واحد كما يعرفه هذا الجوال، ومعه إلى أين وصل في طريقه إلى الخادم.",
        w_c_owner="من يملك أي حقل: الشخص يكتب الملاحظة؛ والمقهى يكتب الحالة.",
        w_c_store="مصدر الحقيقة لكل شاشة. الشاشات تشاهده؛ ولا تنتظر الشبكة أبداً.",
        w_c_outbox="صندوق الصادر: كل طلب فيه تغييرات لم يؤكدها الخادم بعد، الأقدم أولاً.",
        w_c_emit="كل تغيير يُعلن، فتتحدث كل شاشة تشاهد فوراً.",
        w_c_remote="خادم المقهى، متخيَّلاً: يستطيع أن ينقطع، ويضيّع جواباً، ويرفض طلباً، ويغيّر الحالات وحده.",
        w_c_idem="رقم الطلب هو مفتاح عدم التكرار: الطلب نفسه إن أُرسل مرتين يُحفظ مرة.",
        w_c_engine="أرسل ما ينتظر، ثم اجلب ما تغيّر. ويتوقف بهدوء بلا اتصال؛ ويحاول من جديد في المرة القادمة.",
        w_c_push="لا تُرسل إلا حقول الشخص؛ والجواب يقول كم صارت نسخة الخادم حديثة.",
        w_c_refused="الرفض لا يتغير بإعادة المحاولة: علّمه وتابع.",
        w_c_pull="فقط ما تغيّر منذ آخر مزامنة: والمؤشر أعلى إصدار رأيناه.",
        w_c_merge="ادمج حقلاً حقلاً: حالة المقهى تغلب دائماً؛ وملاحظة الخادم فقط إن لم يكن لملاحظتنا تغيير لم يُرسل.",
        w_c_place="اكتب محلياً أولاً: الطلب على الشاشة قبل أن تُجرَّب الشبكة أصلاً.",
        w_c_auto="إن كانت الشبكة موجودة فأرسله الآن؛ وإلا فهو ينتظر في صندوق الصادر.",
        w_t_sync="الطلبات تنتظر بلا اتصال، وتُرسل مرة، والرفض لا يُعاد",
        w_t_merge="ملاحظة كُتبت بلا اتصال وحالة المقهى الجديدة تبقيان معاً",
        w_t_screen="بلا اتصال يظهر الطلب، معلَّماً بأنه ينتظر",
        w_t_pending="الشارة تعدّ ما ينتظر",
        w_t_auto="العودة إلى الاتصال ترسل ما كان ينتظر",
        w_t_sqlite="المزامنة نفسها تعمل على SQLite",
        w_c_pending="مشتق من الطلبات: لا شيء يجب إبقاؤه متزامناً.",
        w_c_reconnect="حين تعود الشبكة، زامن دون أن يُطلب منك.",
        w_c_sqlite="LocalStore نفسه، محفوظاً في SQLite: لا يتغير المحرك ولا الشاشات.",
        w_c_changes="لا يوجد في SQLite تيار للتغييرات: فالمخزن يعلن عن كتاباته بنفسه.",
    ),
}

FILES = {
    "lib/offline/order.dart": """enum SyncState { queued, synced, failed }

// {w_c_order}
class Order {
  const Order({
    required this.id,
    required this.title,
    this.note = '',
    this.status = 'new',
    this.sync = SyncState.queued,
    this.version = 0,
    this.error,
  });

  final String id;
  final String title;
  // {w_c_owner}
  final String note;
  final String status;
  final SyncState sync;
  final int version;
  final String? error;

  Order copyWith({String? note, String? status, SyncState? sync, int? version, String? error}) => Order(
    id: id,
    title: title,
    note: note ?? this.note,
    status: status ?? this.status,
    sync: sync ?? this.sync,
    version: version ?? this.version,
    error: error ?? this.error,
  );
}
""",
    "lib/offline/local_store.dart": """import 'dart:async';

import 'order.dart';

// {w_c_store}
abstract interface class LocalStore {
  Stream<List<Order>> watch();
  Future<List<Order>> all();
  Future<Order?> get(String id);
  Future<void> put(Order order);
  // {w_c_outbox}
  Future<List<Order>> outbox();
  Future<int> cursor();
  Future<void> setCursor(int version);
}

class MemoryLocalStore implements LocalStore {
  final _orders = <String, Order>{};
  var _cursor = 0;
  final _changes = StreamController<List<Order>>.broadcast();

  // {w_c_nogap}
  @override
  Stream<List<Order>> watch() => Stream.multi((listener) {
    listener.add([..._orders.values]);
    final changes = _changes.stream.listen(listener.add);
    listener.onCancel = changes.cancel;
  });

  @override
  Future<List<Order>> all() async => [..._orders.values];

  @override
  Future<Order?> get(String id) async => _orders[id];

  @override
  Future<void> put(Order order) async {
    _orders[order.id] = order;
    // {w_c_emit}
    _changes.add(await all());
  }

  @override
  Future<List<Order>> outbox() async => [
    for (final o in _orders.values)
      if (o.sync == SyncState.queued) o,
  ];

  @override
  Future<int> cursor() async => _cursor;

  @override
  Future<void> setCursor(int version) async => _cursor = version;
}
""",
    "lib/offline/remote.dart": """import 'dart:async';

import 'order.dart';

class Offline implements Exception {
  const Offline();
}

class Refused implements Exception {
  const Refused(this.reason);
  final String reason;
}

// {w_c_remote}
class FakeRemote {
  var online = true;
  var loseNextAnswer = false;
  final soldOut = <String>{};
  final orders = <String, Map<String, Object>>{};
  var _version = 0;

  void _check() {
    if (!online) {
      throw const Offline();
    }
  }

  Future<int> push(Order order) async {
    _check();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (soldOut.contains(order.title)) {
      throw const Refused('Sold out');
    }
    // {w_c_idem}
    final saved = orders.putIfAbsent(order.id, () => {'title': order.title, 'status': 'new'});
    saved['note'] = order.note;
    saved['version'] = ++_version;
    if (loseNextAnswer) {
      loseNextAnswer = false;
      throw const Offline();
    }
    return _version;
  }

  Future<List<Map<String, Object>>> changesSince(int version) async {
    _check();
    return [
      for (final MapEntry(:key, :value) in orders.entries)
        if ((value['version']! as int) > version) {...value, 'id': key},
    ];
  }

  /// The café's side: the barista changes an order's status.
  void setStatus(String id, String status) {
    orders[id]!
      ..['status'] = status
      ..['version'] = ++_version;
  }
}
""",
    "lib/offline/sync_engine.dart": """import 'dart:math';

import 'local_store.dart';
import 'order.dart';
import 'remote.dart';

class SyncReport {
  var sent = 0;
  var refused = 0;
  var pulled = 0;
  var offline = false;

  @override
  String toString() => offline ? 'offline (sent $sent)' : 'sent $sent, refused $refused, pulled $pulled';
}

// {w_c_engine}
class SyncEngine {
  SyncEngine(this.local, this.remote);

  final LocalStore local;
  final FakeRemote remote;

  Future<SyncReport> sync() async {
    final report = SyncReport();
    try {
      for (final order in await local.outbox()) {
        try {
          // {w_c_push}
          final version = await remote.push(order);
          await local.put(order.copyWith(sync: SyncState.synced, version: version));
          report.sent++;
        } on Refused catch (e) {
          // {w_c_refused}
          await local.put(order.copyWith(sync: SyncState.failed, error: e.reason));
          report.refused++;
        }
      }
      // {w_c_pull}
      var cursor = await local.cursor();
      for (final change in await remote.changesSince(cursor)) {
        await _merge(change);
        cursor = max(cursor, change['version']! as int);
        report.pulled++;
      }
      await local.setCursor(cursor);
    } on Offline {
      report.offline = true;
    }
    return report;
  }

  // {w_c_merge}
  Future<void> _merge(Map<String, Object> change) async {
    final id = change['id']! as String;
    final mine = await local.get(id);
    final status = change['status']! as String;
    final version = change['version']! as int;
    if (mine == null) {
      await local.put(Order(id: id, title: change['title']! as String, note: change['note']! as String, status: status, sync: SyncState.synced, version: version));
    } else if (mine.sync == SyncState.queued) {
      await local.put(mine.copyWith(status: status));
    } else {
      await local.put(mine.copyWith(status: status, note: change['note']! as String, version: version));
    }
  }
}
""",
    "lib/offline/providers.dart": """import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_store.dart';
import 'order.dart';
import 'remote.dart';
import 'sync_engine.dart';

final remoteProvider = Provider((ref) => FakeRemote());
final localProvider = Provider<LocalStore>((ref) => MemoryLocalStore());
final syncProvider = Provider((ref) => SyncEngine(ref.watch(localProvider), ref.watch(remoteProvider)));
final ordersProvider = StreamProvider<List<Order>>((ref) => ref.watch(localProvider).watch());

class OnlineNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool online) {
    ref.read(remoteProvider).online = online;
    state = online;
  }
}

final onlineProvider = NotifierProvider<OnlineNotifier, bool>(OnlineNotifier.new);

class LastSync extends Notifier<SyncReport?> {
  @override
  SyncReport? build() => null;

  Future<void> run() async => state = await ref.read(syncProvider).sync();
}

final lastSyncProvider = NotifierProvider<LastSync, SyncReport?>(LastSync.new);

String newId() => List.generate(8, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join();

class Orders {
  Orders(this.ref);

  final Ref ref;

  Future<void> place(String title) async {
    // {w_c_place}
    await ref.read(localProvider).put(Order(id: newId(), title: title));
    // {w_c_auto}
    await ref.read(lastSyncProvider.notifier).run();
  }
}

final ordersActionsProvider = Provider(Orders.new);
""",
    "lib/offline_app.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'offline/order.dart';
import 'offline/providers.dart';

void main() {
  runApp(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        {w_rtl}
        theme: ThemeData(colorSchemeSeed: Colors.teal),
        home: const OrdersPage(),
      ),
    ),
  );
}

const titles = {'Latte': '{w_latte}', 'Cherry cake': '{w_cake}'};
const statuses = {'new': '{w_new}', 'ready': '{w_ready}'};

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(onlineProvider);
    final orders = ref.watch(ordersProvider).value ?? const [];
    final last = ref.watch(lastSyncProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('{w_orders}'),
        actions: [
          const ExcludeSemantics(child: Text('{w_online}')),
          // {w_c_label}
          Semantics(
            label: '{w_online}',
            child: Switch(value: online, onChanged: ref.read(onlineProvider.notifier).set),
          ),
        ],
      ),
      body: ListView(
        children: [
          if (!online)
            const MaterialBanner(
              leading: Icon(Icons.cloud_off),
              content: Text('{w_offline_banner}'),
              actions: [SizedBox()],
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(onPressed: () => ref.read(ordersActionsProvider).place('Latte'), child: const Text('{w_order_latte}')),
                FilledButton(onPressed: () => ref.read(ordersActionsProvider).place('Cherry cake'), child: const Text('{w_order_cake}')),
                OutlinedButton(onPressed: ref.read(lastSyncProvider.notifier).run, child: const Text('{w_sync}')),
                OutlinedButton(
                  onPressed: () {
                    final remote = ref.read(remoteProvider);
                    if (remote.orders.isNotEmpty) {
                      remote.setStatus(remote.orders.keys.first, 'ready');
                    }
                  },
                  child: const Text('{w_mark}'),
                ),
              ],
            ),
          ),
          for (final order in orders)
            ListTile(
              leading: Icon(switch (order.sync) {
                SyncState.queued => Icons.schedule,
                SyncState.synced => Icons.cloud_done,
                SyncState.failed => Icons.error_outline,
              }),
              title: Text(titles[order.title] ?? order.title),
              subtitle: Text(switch (order.sync) {
                SyncState.queued => '{w_queued}',
                SyncState.synced => '{w_synced} · ${statuses[order.status] ?? order.status}',
                SyncState.failed => '{w_failed}: ${order.error}',
              }),
            ),
          if (last != null)
            ListTile(title: Text('{w_last}: $last', textDirection: TextDirection.ltr, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}
""",
    "test/sync_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/offline/local_store.dart';
import 'package:bit_app/offline/order.dart';
import 'package:bit_app/offline/remote.dart';
import 'package:bit_app/offline/sync_engine.dart';

void main() {
  test('{w_t_sync}', () async {
    final local = MemoryLocalStore();
    final remote = FakeRemote()..online = false;
    final engine = SyncEngine(local, remote);

    await local.put(const Order(id: 'a', title: 'Latte'));
    await local.put(const Order(id: 'b', title: 'Cherry cake'));
    debugPrint('offline:           ${await engine.sync()}, waiting: ${(await local.outbox()).length}');

    remote
      ..online = true
      ..loseNextAnswer = true;
    debugPrint('answer lost:       ${await engine.sync()}, waiting: ${(await local.outbox()).length}');
    debugPrint('next sync:         ${await engine.sync()}, waiting: ${(await local.outbox()).length}');
    debugPrint('orders on server:  ${remote.orders.length}');
    expect(remote.orders.length, 2);

    remote.soldOut.add('Muffin');
    await local.put(const Order(id: 'c', title: 'Muffin'));
    debugPrint('sold out:          ${await engine.sync()}');
    debugPrint('again:             ${await engine.sync()}');
    expect((await local.get('c'))!.sync, SyncState.failed);
  });
}
""",
    "test/merge_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/offline/local_store.dart';
import 'package:bit_app/offline/order.dart';
import 'package:bit_app/offline/remote.dart';
import 'package:bit_app/offline/sync_engine.dart';

void main() {
  test('{w_t_merge}', () async {
    final local = MemoryLocalStore();
    final remote = FakeRemote();
    final engine = SyncEngine(local, remote);
    await local.put(const Order(id: 'a', title: 'Latte'));
    await engine.sync();

    // Offline, the person adds a note; meanwhile, the café marks the order ready.
    remote.online = false;
    final mine = (await local.get('a'))!;
    await local.put(mine.copyWith(note: 'No sugar', sync: SyncState.queued));
    remote.setStatus('a', 'ready');

    remote.online = true;
    await engine.sync();
    final merged = (await local.get('a'))!;
    expect(merged.note, 'No sugar');
    expect(merged.status, 'ready');
    expect(remote.orders['a']!['note'], 'No sugar');
    expect(remote.orders['a']!['status'], 'ready');
  });
}
""",
    "test/screen_test.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/offline_app.dart';

void main() {
  testWidgets('{w_t_screen}', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: OrdersPage())));
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(find.text('{w_offline_banner}'), findsOneWidget);

    await tester.tap(find.text('{w_order_latte}'));
    await tester.pumpAndSettle();
    expect(find.text('{w_latte}'), findsOneWidget);
    expect(find.text('{w_queued}'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.tap(find.text('{w_sync}'));
    await tester.pumpAndSettle();
    expect(find.text('{w_synced} · {w_new}'), findsOneWidget);
  });
}
""",
    # Projects
    "lib/offline/pending.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'order.dart';
import 'providers.dart';

// {w_c_pending}
final pendingProvider = Provider<int>(
  (ref) => (ref.watch(ordersProvider).value ?? const []).where((o) => o.sync == SyncState.queued).length,
);
""",
    "test/pending_test.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/offline/order.dart';
import 'package:bit_app/offline/pending.dart';
import 'package:bit_app/offline/providers.dart';

void main() {
  test('{w_t_pending}', () async {
    final container = ProviderContainer.test();
    container.listen(pendingProvider, (previous, next) {});
    container.read(onlineProvider.notifier).set(false);
    await container.read(ordersActionsProvider).place('Latte');
    await container.read(ordersActionsProvider).place('Cherry cake');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(container.read(pendingProvider), 2);

    container.read(onlineProvider.notifier).set(true);
    await container.read(lastSyncProvider.notifier).run();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(container.read(pendingProvider), 0);
    expect((await container.read(localProvider).all()).every((o) => o.sync == SyncState.synced), isTrue);
  });
}
""",
    "lib/offline/auto_sync.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

// {w_c_reconnect}
final autoSyncProvider = Provider<void>((ref) {
  ref.listen(onlineProvider, (wasOnline, online) {
    if (online && wasOnline == false) {
      ref.read(lastSyncProvider.notifier).run();
    }
  });
});
""",
    "test/auto_sync_test.dart": """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/offline/auto_sync.dart';
import 'package:bit_app/offline/providers.dart';

void main() {
  test('{w_t_auto}', () async {
    final container = ProviderContainer.test();
    container.listen(autoSyncProvider, (previous, next) {});
    container.read(onlineProvider.notifier).set(false);
    await container.read(ordersActionsProvider).place('Latte');
    expect((await container.read(localProvider).outbox()).length, 1);

    container.read(onlineProvider.notifier).set(true);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect((await container.read(localProvider).outbox()), isEmpty);
    expect(container.read(remoteProvider).orders.length, 1);
  });
}
""",
    "lib/offline/sqlite_store.dart": """import 'dart:async';

import 'package:sqflite/sqflite.dart';

import 'local_store.dart';
import 'order.dart';

// {w_c_sqlite}
class SqliteLocalStore implements LocalStore {
  SqliteLocalStore(this.db);

  final Database db;
  // {w_c_changes}
  final _changes = StreamController<List<Order>>.broadcast();

  static Future<SqliteLocalStore> open(String path, {DatabaseFactory? factory}) async {
    final db = await (factory ?? databaseFactory).openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, v) async {
          await db.execute(
            'CREATE TABLE orders (id TEXT PRIMARY KEY, title TEXT, note TEXT, status TEXT, sync INTEGER, '
            'version INTEGER, error TEXT, created INTEGER)',
          );
          await db.execute('CREATE TABLE meta (key TEXT PRIMARY KEY, value INTEGER)');
        },
      ),
    );
    return SqliteLocalStore(db);
  }

  Order _row(Map<String, Object?> r) => Order(
    id: r['id']! as String,
    title: r['title']! as String,
    note: r['note']! as String,
    status: r['status']! as String,
    sync: SyncState.values[r['sync']! as int],
    version: r['version']! as int,
    error: r['error'] as String?,
  );

  @override
  Stream<List<Order>> watch() => Stream.multi((listener) {
    // Listen first; send the first snapshot only if no newer list arrived while it was read.
    var changed = false;
    final changes = _changes.stream.listen((list) {
      changed = true;
      listener.add(list);
    });
    listener.onCancel = changes.cancel;
    all().then((list) {
      if (!changed) {
        listener.add(list);
      }
    });
  });

  @override
  Future<List<Order>> all() async => [for (final r in await db.query('orders', orderBy: 'created')) _row(r)];

  @override
  Future<Order?> get(String id) async {
    final rows = await db.query('orders', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : _row(rows.first);
  }

  @override
  Future<void> put(Order o) async {
    final existing = await db.query('orders', columns: ['created'], where: 'id = ?', whereArgs: [o.id]);
    await db.insert('orders', {
      'id': o.id,
      'title': o.title,
      'note': o.note,
      'status': o.status,
      'sync': o.sync.index,
      'version': o.version,
      'error': o.error,
      'created': existing.isEmpty ? DateTime.now().microsecondsSinceEpoch : existing.first['created'],
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    _changes.add(await all());
  }

  @override
  Future<List<Order>> outbox() async => [
    for (final r in await db.query('orders', where: 'sync = ?', whereArgs: [SyncState.queued.index], orderBy: 'created')) _row(r),
  ];

  @override
  Future<int> cursor() async {
    final rows = await db.query('meta', where: 'key = ?', whereArgs: ['cursor']);
    return rows.isEmpty ? 0 : rows.first['value']! as int;
  }

  @override
  Future<void> setCursor(int version) =>
      db.insert('meta', {'key': 'cursor', 'value': version}, conflictAlgorithm: ConflictAlgorithm.replace);
}
""",
    "test/sqlite_store_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bit_app/offline/order.dart';
import 'package:bit_app/offline/remote.dart';
import 'package:bit_app/offline/sqlite_store.dart';
import 'package:bit_app/offline/sync_engine.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('{w_t_sqlite}', () async {
    final local = await SqliteLocalStore.open(inMemoryDatabasePath, factory: databaseFactoryFfi);
    addTearDown(local.db.close);
    final remote = FakeRemote()..online = false;
    final engine = SyncEngine(local, remote);

    await local.put(const Order(id: 'a', title: 'Latte'));
    await local.put(const Order(id: 'b', title: 'Cherry cake'));
    expect((await engine.sync()).offline, isTrue);
    expect([for (final o in await local.outbox()) o.id], ['a', 'b']);

    remote.online = true;
    await engine.sync();
    remote.setStatus('b', 'ready');
    await engine.sync();
    expect((await local.get('b'))!.status, 'ready');
    expect(await local.cursor(), 3);
    expect(await local.outbox(), isEmpty);
  });
}
""",
}

SHOTS = [
    ("offline.png", "lib/offline_app.dart", "switch={w_online}|button={w_order_latte}|button={w_order_cake}|wait=800"),
    ("synced.png", "lib/offline_app.dart",
     "switch={w_online}|button={w_order_latte}|button={w_order_cake}|switch={w_online}|button={w_sync}|wait=1000"),
    ("ready.png", "lib/offline_app.dart",
     "switch={w_online}|button={w_order_latte}|button={w_order_cake}|switch={w_online}|button={w_sync}|wait=800"
     "|button={w_mark}|button={w_sync}|wait=1000"),
]

TESTS = [
    ("sync-test.sh", "test/sync_test.dart"),
    ("merge-test.sh", "test/merge_test.dart"),
    ("screen-test.sh", "test/screen_test.dart"),
    ("projects/pending-test.sh", "test/pending_test.dart"),
    ("projects/auto-sync-test.sh", "test/auto_sync_test.dart"),
    ("projects/sqlite-test.sh", "test/sqlite_store_test.dart"),
]
T["en"]["w_c_nogap"] = "Stream.multi: the first list and the subscription to changes happen at once, so no change can fall between them."
T["ar"]["w_c_nogap"] = "Stream.multi: القائمة الأولى والاشتراك في التغييرات يحدثان معاً، فلا يسقط تغيير بينهما."
T["en"]["w_c_label"] = "The switch is named for screen readers (and for the screenshots): the text beside it is not its name."
T["ar"]["w_c_label"] = "المفتاح له اسم لقارئات الشاشة (ولصور الكتاب): فالنص بجانبه ليس اسمه."
T["en"]["w_c_meanwhile"] = "Offline, the person adds a note; meanwhile, the café marks the order ready."
T["ar"]["w_c_meanwhile"] = "بلا اتصال يضيف الشخص ملاحظة؛ وفي الأثناء يعلّم المقهى الطلب جاهزاً."
FILES["test/merge_test.dart"] = FILES["test/merge_test.dart"].replace(
    "// Offline, the person adds a note; meanwhile, the café marks the order ready.", "// {w_c_meanwhile}")


def main():
    flutter_gallery(HERE, T, FILES, SHOTS, TESTS, packages=["flutter_riverpod", "sqflite", "dev:sqflite_common_ffi"])


if __name__ == "__main__":
    main()
