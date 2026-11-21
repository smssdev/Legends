import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/notes/model.dart';
import 'package:bit_app/notes/note.dart';
import 'package:bit_app/notes/store.dart';

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
  test('النموذج يضيف ويرتّب ويبحث ويحذف ويتراجع', () async {
    final store = MemoryNotesStore(samples);
    final model = NotesModel(store, clock: () => DateTime(2026, 11, 9));
    await model.load();
    expect([for (final n in model.visible) n.id], ['2', '3', '4', '1']);

    await model.add('اتصل بالمخبز!', '');
    expect(model.visible[1].title, 'اتصل بالمخبز!');

    model.search('حليب');
    expect([for (final n in model.visible) n.id], ['1']);
    model.search('');

    final pinned = model.visible.first;
    final index = await model.remove(pinned);
    expect(model.all.any((n) => n.id == '2'), isFalse);
    await model.restore(pinned, index);
    expect(model.visible.first.id, '2');

    // الملاحظات تبقى بعد فتح التطبيق من جديد
    final again = NotesModel(store);
    await again.load();
    expect(again.all.length, 5);
  });
}
