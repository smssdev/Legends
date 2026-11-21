import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'note.dart';

// Where notes are kept. The model does not know which store it has.
abstract interface class NotesStore {
  Future<List<Note>> load();
  Future<void> save(List<Note> notes);
}

// On the device, as one JSON value, with a version: works on phones and on the web.
class PrefsNotesStore implements NotesStore {
  PrefsNotesStore(this.prefs);

  final SharedPreferencesAsync prefs;

  @override
  Future<List<Note>> load() async {
    final text = await prefs.getString('notes');
    if (text == null) {
      return [];
    }
    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      if (json['version'] != 1) {
        return [];
      }
      return [
        for (final item in json['notes'] as List<dynamic>)
          Note.fromJson(item as Map<String, dynamic>),
      ];
    } catch (e) {
      // A damaged value: start empty rather than crash.
      return [];
    }
  }

  @override
  Future<void> save(List<Note> notes) => prefs.setString(
    'notes',
    jsonEncode({
      'version': 1,
      'notes': [for (final n in notes) n.toJson()],
    }),
  );
}

// In memory only: for tests and examples.
class MemoryNotesStore implements NotesStore {
  MemoryNotesStore([List<Note> notes = const []]) : _notes = [...notes];

  List<Note> _notes;

  @override
  Future<List<Note>> load() async => [..._notes];

  @override
  Future<void> save(List<Note> notes) async => _notes = [...notes];
}
