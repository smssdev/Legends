import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/notes/model.dart';
import 'package:bit_app/notes/note.dart';
import 'package:bit_app/notes/store.dart';

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
  test('the model adds, sorts, searches, deletes and undoes', () async {
    final store = MemoryNotesStore(samples);
    final model = NotesModel(store, clock: () => DateTime(2026, 11, 9));
    await model.load();
    expect([for (final n in model.visible) n.id], ['2', '3', '4', '1']);

    await model.add('Call the bakery!', '');
    expect(model.visible[1].title, 'Call the bakery!');

    model.search('milk');
    expect([for (final n in model.visible) n.id], ['1']);
    model.search('');

    final pinned = model.visible.first;
    final index = await model.remove(pinned);
    expect(model.all.any((n) => n.id == '2'), isFalse);
    await model.restore(pinned, index);
    expect(model.visible.first.id, '2');

    // notes survive opening the app again
    final again = NotesModel(store);
    await again.load();
    expect(again.all.length, 5);
  });
}
