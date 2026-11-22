import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_store.dart';
import 'order.dart';
import 'remote.dart';
import 'sync_engine.dart';

final remoteProvider = Provider((ref) => FakeRemote());
final localProvider = Provider<LocalStore>((ref) => MemoryLocalStore());
final syncProvider = Provider(
  (ref) => SyncEngine(ref.watch(localProvider), ref.watch(remoteProvider)),
);
final ordersProvider = StreamProvider<List<Order>>(
  (ref) => ref.watch(localProvider).watch(),
);

class OnlineNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool online) {
    ref.read(remoteProvider).online = online;
    state = online;
  }
}

final onlineProvider = NotifierProvider<OnlineNotifier, bool>(
  OnlineNotifier.new,
);

class LastSync extends Notifier<SyncReport?> {
  @override
  SyncReport? build() => null;

  Future<void> run() async => state = await ref.read(syncProvider).sync();
}

final lastSyncProvider = NotifierProvider<LastSync, SyncReport?>(LastSync.new);

String newId() => List.generate(
  8,
  (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
).join();

class Orders {
  Orders(this.ref);

  final Ref ref;

  Future<void> place(String title) async {
    // اكتب محلياً أولاً: الطلب على الشاشة قبل أن تُجرَّب الشبكة أصلاً.
    await ref.read(localProvider).put(Order(id: newId(), title: title));
    // إن كانت الشبكة موجودة فأرسله الآن؛ وإلا فهو ينتظر في صندوق الصادر.
    await ref.read(lastSyncProvider.notifier).run();
  }
}

final ordersActionsProvider = Provider(Orders.new);
