import 'package:sqflite/sqflite.dart';

class Note {
  const Note({this.id, required this.text, this.done = false});

  factory Note.fromRow(Map<String, Object?> row) => Note(
    id: row['id'] as int,
    text: row['text'] as String,
    done: row['done'] == 1,
  );

  final int? id;
  final String text;
  final bool done;

  // SQLite has no true or false: 1 and 0.
  Map<String, Object?> toRow() => {
    'id': id,
    'text': text,
    'done': done ? 1 : 0,
  };
}

class NotesDb {
  NotesDb._(this.db);

  final Database db;

  static Future<NotesDb> open(String path, {DatabaseFactory? factory}) async {
    final db = await (factory ?? databaseFactory).openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        // الجدول يُنشأ مرة واحدة، أول مرة تُفتح فيها قاعدة البيانات.
        onCreate: (db, version) => db.execute(
          'CREATE TABLE notes (id INTEGER PRIMARY KEY AUTOINCREMENT, text TEXT NOT NULL, done INTEGER NOT NULL)',
        ),
      ),
    );
    return NotesDb._(db);
  }

  Future<int> add(String text) => db.insert('notes', Note(text: text).toRow());

  Future<List<Note>> all() async => [
    for (final row in await db.query('notes', orderBy: 'id')) Note.fromRow(row),
  ];

  // القيم توضع في whereArgs، لا داخل نص SQL أبداً.
  Future<List<Note>> search(String word) async => [
    for (final row in await db.query(
      'notes',
      where: 'text LIKE ?',
      whereArgs: ['%$word%'],
    ))
      Note.fromRow(row),
  ];

  Future<void> setDone(int id, bool done) => db.update(
    'notes',
    {'done': done ? 1 : 0},
    where: 'id = ?',
    whereArgs: [id],
  );

  Future<void> remove(int id) =>
      db.delete('notes', where: 'id = ?', whereArgs: [id]);

  Future<void> close() => db.close();
}
