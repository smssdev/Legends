import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bit_app/notes_db.dart';

void main() {
  // On a computer, tests reach SQLite through FFI; on a phone, sqflite uses the system's own SQLite.
  setUpAll(sqfliteFfiInit);

  test('notes are added, searched, ticked and removed', () async {
    final notes = await NotesDb.open(
      inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    addTearDown(notes.close);

    final milk = await notes.add('Buy milk');
    await notes.add('Call the bakery');
    await notes.add('Buy cups');
    expect(milk, 1);

    expect(
      [for (final n in await notes.search('Buy')) n.text],
      ['Buy milk', 'Buy cups'],
    );

    await notes.setDone(milk, true);
    await notes.remove(2);
    final all = await notes.all();
    expect([for (final n in all) n.text], ['Buy milk', 'Buy cups']);
    expect(all.first.done, isTrue);
  });
}
