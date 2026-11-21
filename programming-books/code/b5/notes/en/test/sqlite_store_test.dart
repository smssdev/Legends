import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bit_app/notes/model.dart';
import 'package:bit_app/notes/note.dart';
import 'package:bit_app/projects_sqlite_store.dart';

// Four notes to start from, written on four days.
final samples = [
  Note(
    id: '1',
    title: 'Shopping',
    body: 'Milk, cups, two lemons',
    edited: DateTime(2026, 11, 1),
  ),
  Note(
    id: '2',
    title: 'Café ideas',
    body: 'A mint tea with honey',
    edited: DateTime(2026, 11, 3),
    pinned: true,
  ),
  Note(
    id: '3',
    title: 'Call the bakery',
    body: 'About the cakes for Friday',
    edited: DateTime(2026, 11, 5),
  ),
  Note(
    id: '4',
    title: 'Recipes',
    body: 'Cherry cake for twelve people',
    edited: DateTime(2026, 11, 2),
  ),
];

void main() {
  setUpAll(sqfliteFfiInit);

  test('the model works the same on SQLite', () async {
    final store = await SqliteNotesStore.open(
      inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    addTearDown(store.db.close);
    await store.save(samples);

    final model = NotesModel(store, clock: () => DateTime(2026, 11, 9));
    await model.load();
    expect([for (final n in model.visible) n.id], ['2', '3', '4', '1']);
    await model.togglePin(model.visible.first);

    final again = NotesModel(store);
    await again.load();
    expect(again.all.any((n) => n.pinned), isFalse);
    expect(again.all.length, 4);
  });
}
