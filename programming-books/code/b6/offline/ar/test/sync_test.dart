import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/offline/local_store.dart';
import 'package:bit_app/offline/order.dart';
import 'package:bit_app/offline/remote.dart';
import 'package:bit_app/offline/sync_engine.dart';

void main() {
  test('الطلبات تنتظر بلا اتصال، وتُرسل مرة، والرفض لا يُعاد', () async {
    final local = MemoryLocalStore();
    final remote = FakeRemote()..online = false;
    final engine = SyncEngine(local, remote);

    await local.put(const Order(id: 'a', title: 'Latte'));
    await local.put(const Order(id: 'b', title: 'Cherry cake'));
    debugPrint(
      'offline:           ${await engine.sync()}, waiting: ${(await local.outbox()).length}',
    );

    remote
      ..online = true
      ..loseNextAnswer = true;
    debugPrint(
      'answer lost:       ${await engine.sync()}, waiting: ${(await local.outbox()).length}',
    );
    debugPrint(
      'next sync:         ${await engine.sync()}, waiting: ${(await local.outbox()).length}',
    );
    debugPrint('orders on server:  ${remote.orders.length}');
    expect(remote.orders.length, 2);

    remote.soldOut.add('Muffin');
    await local.put(const Order(id: 'c', title: 'Muffin'));
    debugPrint('sold out:          ${await engine.sync()}');
    debugPrint('again:             ${await engine.sync()}');
    expect((await local.get('c'))!.sync, SyncState.failed);
  });
}
