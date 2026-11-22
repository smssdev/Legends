import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bit_app/offline/order.dart';
import 'package:bit_app/offline/remote.dart';
import 'package:bit_app/offline/sqlite_store.dart';
import 'package:bit_app/offline/sync_engine.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('the same sync works on SQLite', () async {
    final local = await SqliteLocalStore.open(
      inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
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
