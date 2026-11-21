import 'package:material_ui/material_ui.dart';

import 'note.dart';
import 'store.dart';

// Everything the screens can do with notes, and the only place that changes them.
class NotesModel extends ChangeNotifier {
  // The clock is given, so tests decide what time it is.
  NotesModel(this.store, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  final NotesStore store;
  final DateTime Function() clock;
  var _notes = <Note>[];
  var loading = true;
  var query = '';

  List<Note> get all => List.unmodifiable(_notes);

  // What the list shows: the search applied, pinned first, then the newest.
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

  // Returned so that Undo can put the note back where it was.
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

  // Every change ends here: tell the screens, then write to the store.
  Future<void> _save() async {
    notifyListeners();
    await store.save(_notes);
  }
}
