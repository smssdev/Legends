import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'note.dart';

// مكان حفظ الملاحظات. والنموذج لا يعرف أي مخزن معه.
abstract interface class NotesStore {
  Future<List<Note>> load();
  Future<void> save(List<Note> notes);
}

// على الجهاز، كقيمة JSON واحدة لها إصدار: تعمل على الجوال وعلى الويب.
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
      // قيمة تالفة: ابدأ فارغاً بدل الانهيار.
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

// في الذاكرة فقط: للاختبارات والأمثلة.
class MemoryNotesStore implements NotesStore {
  MemoryNotesStore([List<Note> notes = const []]) : _notes = [...notes];

  List<Note> _notes;

  @override
  Future<List<Note>> load() async => [..._notes];

  @override
  Future<void> save(List<Note> notes) async => _notes = [...notes];
}
