import 'package:sqflite/sqflite.dart';

import 'notes/note.dart';
import 'notes/store.dart';

// The same store, kept in SQLite: the model and the screens do not change at all.
class SqliteNotesStore implements NotesStore {
  SqliteNotesStore(this.db);

  final Database db;

  static Future<SqliteNotesStore> open(
    String path, {
    DatabaseFactory? factory,
  }) async {
    final db = await (factory ?? databaseFactory).openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) => db.execute(
          'CREATE TABLE notes (id TEXT PRIMARY KEY, title TEXT NOT NULL, body TEXT NOT NULL, '
          'pinned INTEGER NOT NULL, edited TEXT NOT NULL)',
        ),
      ),
    );
    return SqliteNotesStore(db);
  }

  @override
  Future<List<Note>> load() async => [
    for (final row in await db.query('notes'))
      Note(
        id: row['id'] as String,
        title: row['title'] as String,
        body: row['body'] as String,
        pinned: row['pinned'] == 1,
        edited: DateTime.parse(row['edited'] as String),
      ),
  ];

  // Saving the whole list in one transaction: all of it, or nothing.
  @override
  Future<void> save(List<Note> notes) => db.transaction((txn) async {
    await txn.delete('notes');
    for (final n in notes) {
      await txn.insert('notes', {...n.toJson(), 'pinned': n.pinned ? 1 : 0});
    }
  });
}
