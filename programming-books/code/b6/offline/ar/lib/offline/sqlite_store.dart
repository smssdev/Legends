import 'dart:async';

import 'package:sqflite/sqflite.dart';

import 'local_store.dart';
import 'order.dart';

// LocalStore نفسه، محفوظاً في SQLite: لا يتغير المحرك ولا الشاشات.
class SqliteLocalStore implements LocalStore {
  SqliteLocalStore(this.db);

  final Database db;
  // لا يوجد في SQLite تيار للتغييرات: فالمخزن يعلن عن كتاباته بنفسه.
  final _changes = StreamController<List<Order>>.broadcast();

  static Future<SqliteLocalStore> open(
    String path, {
    DatabaseFactory? factory,
  }) async {
    final db = await (factory ?? databaseFactory).openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, v) async {
          await db.execute(
            'CREATE TABLE orders (id TEXT PRIMARY KEY, title TEXT, note TEXT, status TEXT, sync INTEGER, '
            'version INTEGER, error TEXT, created INTEGER)',
          );
          await db.execute(
            'CREATE TABLE meta (key TEXT PRIMARY KEY, value INTEGER)',
          );
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
  Future<List<Order>> all() async => [
    for (final r in await db.query('orders', orderBy: 'created')) _row(r),
  ];

  @override
  Future<Order?> get(String id) async {
    final rows = await db.query('orders', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : _row(rows.first);
  }

  @override
  Future<void> put(Order o) async {
    final existing = await db.query(
      'orders',
      columns: ['created'],
      where: 'id = ?',
      whereArgs: [o.id],
    );
    await db.insert('orders', {
      'id': o.id,
      'title': o.title,
      'note': o.note,
      'status': o.status,
      'sync': o.sync.index,
      'version': o.version,
      'error': o.error,
      'created': existing.isEmpty
          ? DateTime.now().microsecondsSinceEpoch
          : existing.first['created'],
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    _changes.add(await all());
  }

  @override
  Future<List<Order>> outbox() async => [
    for (final r in await db.query(
      'orders',
      where: 'sync = ?',
      whereArgs: [SyncState.queued.index],
      orderBy: 'created',
    ))
      _row(r),
  ];

  @override
  Future<int> cursor() async {
    final rows = await db.query(
      'meta',
      where: 'key = ?',
      whereArgs: ['cursor'],
    );
    return rows.isEmpty ? 0 : rows.first['value']! as int;
  }

  @override
  Future<void> setCursor(int version) => db.insert('meta', {
    'key': 'cursor',
    'value': version,
  }, conflictAlgorithm: ConflictAlgorithm.replace);
}
