import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bit_app/notes/model.dart';
import 'package:bit_app/notes/note.dart';
import 'package:bit_app/projects_sqlite_store.dart';

// Four notes to start from, written on four days.
final samples = [
  Note(
    id: '1',
    title: 'مشتريات',
    body: 'حليب وأكواب وليمونتان',
    edited: DateTime(2026, 11, 1),
  ),
  Note(
    id: '2',
    title: 'أفكار للمقهى',
    body: 'شاي بالنعناع مع العسل',
    edited: DateTime(2026, 11, 3),
    pinned: true,
  ),
  Note(
    id: '3',
    title: 'اتصل بالمخبز',
    body: 'بخصوص كيك الجمعة',
    edited: DateTime(2026, 11, 5),
  ),
  Note(
    id: '4',
    title: 'وصفات',
    body: 'كيك الكرز لاثني عشر شخصاً',
    edited: DateTime(2026, 11, 2),
  ),
];

void main() {
  setUpAll(sqfliteFfiInit);

  test('النموذج يعمل كما هو على SQLite', () async {
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
