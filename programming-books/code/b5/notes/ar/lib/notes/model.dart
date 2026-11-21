import 'package:material_ui/material_ui.dart';

import 'note.dart';
import 'store.dart';

// كل ما تستطيع الشاشات فعله بالملاحظات، والمكان الوحيد الذي يغيّرها.
class NotesModel extends ChangeNotifier {
  // الساعة تُعطى من الخارج، فتقرر الاختبارات كم الساعة.
  NotesModel(this.store, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  final NotesStore store;
  final DateTime Function() clock;
  var _notes = <Note>[];
  var loading = true;
  var query = '';

  List<Note> get all => List.unmodifiable(_notes);

  // ما تعرضه القائمة: بعد البحث، المثبّتة أولاً، ثم الأحدث.
  List<Note> get visible {
    final q = query.trim().toLowerCase();
    final found = [
      for (final n in _notes)
        if (q.isEmpty ||
            n.title.toLowerCase().contains(q) ||
            n.body.toLowerCase().contains(q))
          n,
    ];
    found.sort((a, b) {
      if (a.pinned != b.pinned) {
        return a.pinned ? -1 : 1;
      }
      return b.edited.compareTo(a.edited);
    });
    return found;
  }

  Future<void> load() async {
    _notes = await store.load();
    loading = false;
    notifyListeners();
  }

  void search(String text) {
    query = text;
    notifyListeners();
  }

  Future<void> add(String title, String body) {
    final now = clock();
    _notes.add(
      Note(
        id: '${now.microsecondsSinceEpoch}',
        title: title,
        body: body,
        edited: now,
      ),
    );
    return _save();
  }

  Future<void> update(
    Note note, {
    required String title,
    required String body,
  }) {
    _replace(note.copyWith(title: title, body: body, edited: clock()));
    return _save();
  }

  Future<void> togglePin(Note note) {
    _replace(note.copyWith(pinned: !note.pinned));
    return _save();
  }

  // يُعاد ليضع «تراجع» الملاحظة في مكانها.
  Future<int> remove(Note note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    _notes.removeAt(index);
    await _save();
    return index;
  }

  Future<void> restore(Note note, int index) {
    _notes.insert(index, note);
    return _save();
  }

  void _replace(Note note) {
    _notes[_notes.indexWhere((n) => n.id == note.id)] = note;
  }

  // كل تغيير ينتهي هنا: أخبر الشاشات، ثم اكتب في المخزن.
  Future<void> _save() async {
    notifyListeners();
    await store.save(_notes);
  }
}
