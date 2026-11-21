"""Writes the project of Book 5, chapter "Project: A Complete Notes App", in English and Arabic: one app in
several files, with its tests, photographed after real taps and typing, in the language of each edition.
Run: python3 make.py   (needs Flutter 3.50.1, Node.js and Playwright's Chromium; downloads the packages once)
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import flutter_gallery  # noqa: E402

T = {
    "en": dict(
        w_lang="en",
        w_c_note="One note: plain data, with copyWith to change it without changing the original.",
        w_c_store="Where notes are kept. The model does not know which store it has.",
        w_c_prefs="On the device, as one JSON value, with a version: works on phones and on the web.",
        w_c_damaged="A damaged value: start empty rather than crash.",
        w_c_memory="In memory only: for tests and examples.",
        w_c_model="Everything the screens can do with notes, and the only place that changes them.",
        w_c_clock="The clock is given, so tests decide what time it is.",
        w_c_visible="What the list shows: the search applied, pinned first, then the newest.",
        w_c_index="Returned so that Undo can put the note back where it was.",
        w_c_save="Every change ends here: tell the screens, then write to the store.",
        w_c_loading="The first frame: the notes are still being read.",
        w_c_dismiss="Swipe to delete; Undo puts it back.",
        w_c_validate="The form refuses a note without a title.",
        w_c_route="The same page adds and edits: with a note, it edits it.",
        w_t_model="the model adds, sorts, searches, deletes and undoes",
        w_t_store="notes survive opening the app again",
        w_t_app="a note is written, swiped away, and brought back",
        w_n1="Shopping", w_b1="Milk, cups, two lemons",
        w_n2="Café ideas", w_b2="A mint tea with honey",
        w_n3="Call the bakery", w_b3="About the cakes for Friday",
        w_n4="Recipes", w_b4="Cherry cake for twelve people",
        w_s_milk="milk",
        # Projects
        w_stats="Statistics", w_c_stats="Everything on this page is computed from the model: nothing is stored twice.",
        w_s_notes="Notes", w_s_pinned="Pinned", w_s_words="Words", w_s_longest="Longest note",
        w_sort="Sort", w_newest="Newest first", w_oldest="Oldest first", w_az="A to Z",
        w_c_sort="A pure function: the same notes and the same order always give the same list.",
        w_c_compare="compareTo on strings is fine for English; for Arabic, see the hint.",
        w_t_sort="the three orders",
        w_c_sqlite="The same store, kept in SQLite: the model and the screens do not change at all.",
        w_c_replace="Saving the whole list in one transaction: all of it, or nothing.",
        w_t_sqlite="the model works the same on SQLite",
    ),
    "ar": dict(
        w_lang="ar",
        w_c_note="ملاحظة واحدة: بيانات بسيطة، مع copyWith لتغييرها دون تغيير الأصل.",
        w_c_store="مكان حفظ الملاحظات. والنموذج لا يعرف أي مخزن معه.",
        w_c_prefs="على الجهاز، كقيمة JSON واحدة لها إصدار: تعمل على الجوال وعلى الويب.",
        w_c_damaged="قيمة تالفة: ابدأ فارغاً بدل الانهيار.",
        w_c_memory="في الذاكرة فقط: للاختبارات والأمثلة.",
        w_c_model="كل ما تستطيع الشاشات فعله بالملاحظات، والمكان الوحيد الذي يغيّرها.",
        w_c_clock="الساعة تُعطى من الخارج، فتقرر الاختبارات كم الساعة.",
        w_c_visible="ما تعرضه القائمة: بعد البحث، المثبّتة أولاً، ثم الأحدث.",
        w_c_index="يُعاد ليضع «تراجع» الملاحظة في مكانها.",
        w_c_save="كل تغيير ينتهي هنا: أخبر الشاشات، ثم اكتب في المخزن.",
        w_c_loading="أول إطار: ما زالت الملاحظات تُقرأ.",
        w_c_dismiss="اسحب للحذف؛ و«تراجع» تعيدها.",
        w_c_validate="النموذج يرفض ملاحظة بلا عنوان.",
        w_c_route="الصفحة نفسها تضيف وتعدّل: مع ملاحظة، تعدّلها.",
        w_t_model="النموذج يضيف ويرتّب ويبحث ويحذف ويتراجع",
        w_t_store="الملاحظات تبقى بعد فتح التطبيق من جديد",
        w_t_app="ملاحظة تُكتب، وتُسحب، وتعود",
        w_n1="مشتريات", w_b1="حليب وأكواب وليمونتان",
        w_n2="أفكار للمقهى", w_b2="شاي بالنعناع مع العسل",
        w_n3="اتصل بالمخبز", w_b3="بخصوص كيك الجمعة",
        w_n4="وصفات", w_b4="كيك الكرز لاثني عشر شخصاً",
        w_s_milk="حليب",
        w_stats="إحصاءات", w_c_stats="كل ما في هذه الصفحة محسوب من النموذج: لا شيء يُحفظ مرتين.",
        w_s_notes="الملاحظات", w_s_pinned="المثبّتة", w_s_words="الكلمات", w_s_longest="أطول ملاحظة",
        w_sort="الترتيب", w_newest="الأحدث أولاً", w_oldest="الأقدم أولاً", w_az="أبجدياً",
        w_c_sort="دالة نقية: الملاحظات نفسها والترتيب نفسه يعطيان القائمة نفسها دائماً.",
        w_c_compare="compareTo على النصوص تكفي للإنجليزية؛ وللعربية انظر التلميح.",
        w_t_sort="الترتيبات الثلاثة",
        w_c_sqlite="المخزن نفسه، محفوظاً في SQLite: لا يتغير النموذج ولا الشاشات أبداً.",
        w_c_replace="حفظ القائمة كلها في معاملة واحدة: كلها، أو لا شيء.",
        w_t_sqlite="النموذج يعمل كما هو على SQLite",
    ),
}

ARB_EN = """{
  "@@locale": "en",
  "appTitle": "Bit Notes",
  "newNote": "New note",
  "editNote": "Edit note",
  "search": "Search notes",
  "empty": "No notes yet. Tap New note to write one.",
  "noMatch": "No note matches your search",
  "title": "Title",
  "body": "Note",
  "save": "Save",
  "titleNeeded": "A note needs a title",
  "deleted": "Note deleted",
  "undo": "Undo",
  "pin": "Pin {title}",
  "@pin": {"placeholders": {"title": {"type": "String"}}},
  "unpin": "Unpin {title}",
  "@unpin": {"placeholders": {"title": {"type": "String"}}},
  "edited": "{day}",
  "@edited": {"placeholders": {"day": {"type": "DateTime", "format": "yMMMd"}}},
  "count": "{count, plural, =0{No notes} =1{1 note} other{{count} notes}}",
  "@count": {"placeholders": {"count": {"type": "int"}}}
}
"""

ARB_AR = """{
  "@@locale": "ar",
  "appTitle": "ملاحظات بِت",
  "newNote": "ملاحظة جديدة",
  "editNote": "تعديل الملاحظة",
  "search": "ابحث في الملاحظات",
  "empty": "لا ملاحظات بعد. المس «ملاحظة جديدة» لتكتب واحدة.",
  "noMatch": "لا ملاحظة تطابق بحثك",
  "title": "العنوان",
  "body": "الملاحظة",
  "save": "احفظ",
  "titleNeeded": "الملاحظة تحتاج عنواناً",
  "deleted": "حُذفت الملاحظة",
  "undo": "تراجع",
  "pin": "ثبّت {title}",
  "unpin": "ألغِ تثبيت {title}",
  "edited": "{day}",
  "count": "{count, plural, =0{لا ملاحظات} =1{ملاحظة واحدة} =2{ملاحظتان} few{{count} ملاحظات} many{{count} ملاحظة} other{{count} ملاحظة}}"
}
"""

SAMPLES = """
// Four notes to start from, written on four days.
final samples = [
  Note(id: '1', title: '{w_n1}', body: '{w_b1}', edited: DateTime(2026, 11, 1)),
  Note(id: '2', title: '{w_n2}', body: '{w_b2}', edited: DateTime(2026, 11, 3), pinned: true),
  Note(id: '3', title: '{w_n3}', body: '{w_b3}', edited: DateTime(2026, 11, 5)),
  Note(id: '4', title: '{w_n4}', body: '{w_b4}', edited: DateTime(2026, 11, 2)),
];
"""

PREFS_TEST = """import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
"""

APP_HEAD = """MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: delegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(colorSchemeSeed: Colors.brown),
      darkTheme: ThemeData(colorSchemeSeed: Colors.brown, brightness: Brightness.dark),"""

FILES = {
    "root/analysis_options.yaml": """include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - build/**
    - lib/l10n/app_localizations*.dart
""",
    "root/l10n.yaml": """arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
nullable-getter: false
""",
    "lib/l10n/app_en.arb": ARB_EN,
    "lib/l10n/app_ar.arb": ARB_AR,
    "lib/delegates.dart": """import 'package:material_ui/material_ui.dart';

import 'l10n/app_localizations.dart';

// As in Chapter 13.
const delegates = <LocalizationsDelegate<Object?>>[AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates];
""",
    "lib/notes/note.dart": """// {w_c_note}
class Note {
  const Note({required this.id, required this.title, this.body = '', this.pinned = false, required this.edited});

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    pinned: json['pinned'] as bool,
    edited: DateTime.parse(json['edited'] as String),
  );

  final String id;
  final String title;
  final String body;
  final bool pinned;
  final DateTime edited;

  Note copyWith({String? title, String? body, bool? pinned, DateTime? edited}) => Note(
    id: id,
    title: title ?? this.title,
    body: body ?? this.body,
    pinned: pinned ?? this.pinned,
    edited: edited ?? this.edited,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'pinned': pinned,
    'edited': edited.toIso8601String(),
  };
}
""",
    "lib/notes/store.dart": """import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'note.dart';

// {w_c_store}
abstract interface class NotesStore {
  Future<List<Note>> load();
  Future<void> save(List<Note> notes);
}

// {w_c_prefs}
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
      return [for (final item in json['notes'] as List<dynamic>) Note.fromJson(item as Map<String, dynamic>)];
    } catch (e) {
      // {w_c_damaged}
      return [];
    }
  }

  @override
  Future<void> save(List<Note> notes) =>
      prefs.setString('notes', jsonEncode({'version': 1, 'notes': [for (final n in notes) n.toJson()]}));
}

// {w_c_memory}
class MemoryNotesStore implements NotesStore {
  MemoryNotesStore([List<Note> notes = const []]) : _notes = [...notes];

  List<Note> _notes;

  @override
  Future<List<Note>> load() async => [..._notes];

  @override
  Future<void> save(List<Note> notes) async => _notes = [...notes];
}
""",
    "lib/notes/model.dart": """import 'package:material_ui/material_ui.dart';

import 'note.dart';
import 'store.dart';

// {w_c_model}
class NotesModel extends ChangeNotifier {
  // {w_c_clock}
  NotesModel(this.store, {DateTime Function()? clock}) : clock = clock ?? DateTime.now;

  final NotesStore store;
  final DateTime Function() clock;
  var _notes = <Note>[];
  var loading = true;
  var query = '';

  List<Note> get all => List.unmodifiable(_notes);

  // {w_c_visible}
  List<Note> get visible {
    final q = query.trim().toLowerCase();
    final found = [
      for (final n in _notes)
        if (q.isEmpty || n.title.toLowerCase().contains(q) || n.body.toLowerCase().contains(q)) n,
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
    _notes.add(Note(id: '${now.microsecondsSinceEpoch}', title: title, body: body, edited: now));
    return _save();
  }

  Future<void> update(Note note, {required String title, required String body}) {
    _replace(note.copyWith(title: title, body: body, edited: clock()));
    return _save();
  }

  Future<void> togglePin(Note note) {
    _replace(note.copyWith(pinned: !note.pinned));
    return _save();
  }

  // {w_c_index}
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

  // {w_c_save}
  Future<void> _save() async {
    notifyListeners();
    await store.save(_notes);
  }
}
""",
    "lib/notes/list_page.dart": """import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import 'edit_page.dart';
import 'model.dart';
import 'note.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final model = context.watch<NotesModel>();
    final notes = model.visible;
    return Scaffold(
      appBar: AppBar(title: Text(l.appTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              hintText: l.search,
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              onChanged: context.read<NotesModel>().search,
            ),
          ),
          Expanded(
            child: switch (model) {
              // {w_c_loading}
              NotesModel(loading: true) => const Center(child: CircularProgressIndicator()),
              NotesModel(all: []) => _Message(icon: Icons.note_alt_outlined, text: l.empty),
              _ when notes.isEmpty => _Message(icon: Icons.search_off, text: l.noMatch),
              _ => ListView.builder(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: notes.length,
                itemBuilder: (context, i) => _NoteTile(note: notes[i]),
              ),
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openEditor(context),
        icon: const Icon(Icons.edit),
        label: Text(l.newNote),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note});

  final Note note;

  Future<void> delete(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final model = context.read<NotesModel>();
    final messenger = ScaffoldMessenger.of(context);
    final index = await model.remove(note);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l.deleted),
        action: SnackBarAction(label: l.undo, onPressed: () => model.restore(note, index)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // {w_c_dismiss}
    return Dismissible(
      key: ValueKey(note.id),
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 24),
        child: const Icon(Icons.delete),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => delete(context),
      child: ListTile(
        title: Text(note.title),
        subtitle: Text(
          note.body.isEmpty ? l.edited(note.edited) : '${l.edited(note.edited)} · ${note.body}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          tooltip: note.pinned ? l.unpin(note.title) : l.pin(note.title),
          icon: note.pinned
              ? Icon(Icons.push_pin, color: Theme.of(context).colorScheme.primary)
              : const Icon(Icons.push_pin_outlined),
          onPressed: () => context.read<NotesModel>().togglePin(note),
        ),
        onTap: () => openEditor(context, note),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [Icon(icon, size: 64), Text(text, textAlign: TextAlign.center)],
        ),
      ),
    );
  }
}
""",
    "lib/notes/edit_page.dart": """import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import 'model.dart';
import 'note.dart';

// {w_c_route}
Future<void> openEditor(BuildContext context, [Note? note]) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) => EditPage(note: note)));

class EditPage extends StatefulWidget {
  const EditPage({super.key, this.note});

  final Note? note;

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  final form = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.note?.title);
  late final body = TextEditingController(text: widget.note?.body);

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) {
      return;
    }
    final model = context.read<NotesModel>();
    final note = widget.note;
    if (note == null) {
      await model.add(title.text.trim(), body.text.trim());
    } else {
      await model.update(note, title: title.text.trim(), body: body.text.trim());
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? l.newNote : l.editNote),
        actions: [TextButton(onPressed: save, child: Text(l.save))],
      ),
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: title,
              autofocus: widget.note == null,
              decoration: InputDecoration(labelText: l.title),
              textInputAction: TextInputAction.next,
              // {w_c_validate}
              validator: (v) => (v ?? '').trim().isEmpty ? l.titleNeeded : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: body,
              decoration: InputDecoration(labelText: l.body, alignLabelWithHint: true),
              minLines: 6,
              maxLines: null,
            ),
          ],
        ),
      ),
    );
  }
}
""",
    "lib/notes_app.dart": """import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'delegates.dart';
import 'l10n/app_localizations.dart';
import 'notes/list_page.dart';
import 'notes/model.dart';
import 'notes/store.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      // The notes load after the first frame, with a spinner: there may be many.
      create: (context) => NotesModel(PrefsNotesStore(SharedPreferencesAsync()))..load(),
      child: const NotesApp(),
    ),
  );
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return """ + APP_HEAD + """
      home: const NotesPage(),
    );
  }
}
""",
    "test/model_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/notes/model.dart';
import 'package:bit_app/notes/note.dart';
import 'package:bit_app/notes/store.dart';
""" + SAMPLES + """
void main() {
  test('{w_t_model}', () async {
    final store = MemoryNotesStore(samples);
    final model = NotesModel(store, clock: () => DateTime(2026, 11, 9));
    await model.load();
    expect([for (final n in model.visible) n.id], ['2', '3', '4', '1']);

    await model.add('{w_n3}!', '');
    expect(model.visible[1].title, '{w_n3}!');

    model.search('{w_s_milk}');
    expect([for (final n in model.visible) n.id], ['1']);
    model.search('');

    final pinned = model.visible.first;
    final index = await model.remove(pinned);
    expect(model.all.any((n) => n.id == '2'), isFalse);
    await model.restore(pinned, index);
    expect(model.visible.first.id, '2');

    // {w_t_store}
    final again = NotesModel(store);
    await again.load();
    expect(again.all.length, 5);
  });
}
""",
    "test/app_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:bit_app/notes/model.dart';
import 'package:bit_app/notes/store.dart';
import 'package:bit_app/notes_app.dart';

void main() {
  testWidgets('{w_t_app}', (tester) async {
    final model = NotesModel(MemoryNotesStore())..load();
    await tester.pumpWidget(ChangeNotifierProvider.value(value: model, child: const NotesApp()));
    await tester.pumpAndSettle();
    expect(find.text('No notes yet. Tap New note to write one.'), findsOneWidget);

    await tester.tap(find.text('New note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('A note needs a title'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'Shopping');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Shopping'), findsOneWidget);

    await tester.drag(find.text('Shopping'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Shopping'), findsNothing);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Shopping'), findsOneWidget);
  });
}
""",
    # Projects
    "projects/stats.dart": """import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'delegates.dart';
import 'l10n/app_localizations.dart';
import 'notes/model.dart';
import 'notes/note.dart';
import 'notes/store.dart';
""" + SAMPLES + """
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => NotesModel(MemoryNotesStore(samples))..load(),
      child: """ + APP_HEAD.replace("\n      ", "\n        ") + """
        home: const StatsPage(),
      ),
    ),
  );
}

// {w_c_stats}
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NotesModel>().all;
    int words(Note n) => '${n.title} ${n.body}'.split(RegExp(r'\\s+')).where((w) => w.isNotEmpty).length;
    final longest = notes.isEmpty ? null : notes.reduce((a, b) => words(a) >= words(b) ? a : b);
    final rows = [
      (Icons.notes, '{w_s_notes}', '${notes.length}'),
      (Icons.push_pin, '{w_s_pinned}', '${notes.where((n) => n.pinned).length}'),
      (Icons.short_text, '{w_s_words}', '${notes.fold(0, (sum, n) => sum + words(n))}'),
      (Icons.straighten, '{w_s_longest}', longest?.title ?? '-'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('{w_stats}')),
      body: ListView(
        children: [
          for (final (icon, label, value) in rows)
            ListTile(
              leading: Icon(icon),
              title: Text(label),
              trailing: Text(value, style: Theme.of(context).textTheme.titleLarge),
            ),
        ],
      ),
    );
  }
}
""",
    "projects/sorted.dart": """import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'delegates.dart';
import 'l10n/app_localizations.dart';
import 'notes/model.dart';
import 'notes/note.dart';
import 'notes/store.dart';
""" + SAMPLES + """
enum Sort { newest, oldest, az }

// {w_c_sort}
List<Note> sortNotes(List<Note> notes, Sort sort) {
  final sorted = [...notes];
  switch (sort) {
    case Sort.newest:
      sorted.sort((a, b) => b.edited.compareTo(a.edited));
    case Sort.oldest:
      sorted.sort((a, b) => a.edited.compareTo(b.edited));
    case Sort.az:
      // {w_c_compare}
      sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }
  return sorted;
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => NotesModel(MemoryNotesStore(samples))..load(),
      child: """ + APP_HEAD.replace("\n      ", "\n        ") + """
        home: const SortedPage(),
      ),
    ),
  );
}

class SortedPage extends StatefulWidget {
  const SortedPage({super.key});

  @override
  State<SortedPage> createState() => _SortedPageState();
}

class _SortedPageState extends State<SortedPage> {
  var sort = Sort.newest;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final notes = sortNotes(context.watch<NotesModel>().all, sort);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          PopupMenuButton<Sort>(
            tooltip: '{w_sort}',
            icon: const Icon(Icons.sort),
            initialValue: sort,
            onSelected: (s) => setState(() => sort = s),
            itemBuilder: (context) => const [
              PopupMenuItem(value: Sort.newest, child: Text('{w_newest}')),
              PopupMenuItem(value: Sort.oldest, child: Text('{w_oldest}')),
              PopupMenuItem(value: Sort.az, child: Text('{w_az}')),
            ],
          ),
        ],
      ),
      body: ListView(
        children: [
          for (final n in notes) ListTile(title: Text(n.title), subtitle: Text(l.edited(n.edited))),
        ],
      ),
    );
  }
}
""",
    "test/sorted_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/projects_sorted.dart';

void main() {
  test('{w_t_sort}', () {
    List<String> ids(Sort s) => [for (final n in sortNotes(samples, s)) n.id];
    expect(ids(Sort.newest), ['3', '2', '4', '1']);
    expect(ids(Sort.oldest), ['1', '4', '2', '3']);
    expect(ids(Sort.az), {w_az_ids});
  });
}
""",
    "projects/sqlite_store.dart": """import 'package:sqflite/sqflite.dart';

import 'notes/note.dart';
import 'notes/store.dart';

// {w_c_sqlite}
class SqliteNotesStore implements NotesStore {
  SqliteNotesStore(this.db);

  final Database db;

  static Future<SqliteNotesStore> open(String path, {DatabaseFactory? factory}) async {
    final db = await (factory ?? databaseFactory).openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) => db.execute(
          'CREATE TABLE notes (id TEXT PRIMARY KEY, title TEXT NOT NULL, body TEXT NOT NULL, '
          'pinned INTEGER NOT NULL, edited TEXT NOT NULL)',
        ),
      ),
    );
    return SqliteNotesStore(db);
  }

  @override
  Future<List<Note>> load() async => [
    for (final row in await db.query('notes'))
      Note(
        id: row['id'] as String,
        title: row['title'] as String,
        body: row['body'] as String,
        pinned: row['pinned'] == 1,
        edited: DateTime.parse(row['edited'] as String),
      ),
  ];

  // {w_c_replace}
  @override
  Future<void> save(List<Note> notes) => db.transaction((txn) async {
    await txn.delete('notes');
    for (final n in notes) {
      await txn.insert('notes', {...n.toJson(), 'pinned': n.pinned ? 1 : 0});
    }
  });
}
""",
    "test/sqlite_store_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bit_app/notes/model.dart';
import 'package:bit_app/notes/note.dart';
import 'package:bit_app/projects_sqlite_store.dart';
""" + SAMPLES + """
void main() {
  setUpAll(sqfliteFfiInit);

  test('{w_t_sqlite}', () async {
    final store = await SqliteNotesStore.open(inMemoryDatabasePath, factory: databaseFactoryFfi);
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
""",
}
T["en"]["w_az_ids"] = "['2', '3', '4', '1']"
T["ar"]["w_az_ids"] = "['2', '3', '1', '4']"

NEW = "button={w_new}|type={w_title}=>{t}|type={w_note}=>{b}|button={w_save}|wait=800"
T["en"].update(w_new="New note", w_title="Title", w_note="Note", w_save="Save", w_undo="Undo",
               w_pin2="Pin Café ideas", w_search_q="cake")
T["ar"].update(w_new="ملاحظة جديدة", w_title="العنوان", w_note="الملاحظة", w_save="احفظ", w_undo="تراجع",
               w_pin2="ثبّت أفكار للمقهى", w_search_q="كيك")
THREE = "|".join(NEW.replace("{t}", f"{{w_n{i}}}").replace("{b}", f"{{w_b{i}}}") for i in (1, 2, 3))

SHOTS = [
    ("empty.png", "lib/notes_app.dart?lang={w_lang}", ""),
    ("editor.png", "lib/notes_app.dart?lang={w_lang}", "button={w_new}|type={w_title}=>{w_n1}|type={w_note}=>{w_b1}"),
    ("invalid.png", "lib/notes_app.dart?lang={w_lang}", "button={w_new}|button={w_save}"),
    ("list.png", "lib/notes_app.dart?lang={w_lang}", THREE + "|button={w_pin2}|reload=1"),
    ("search.png", "lib/notes_app.dart?lang={w_lang}", THREE + "|at=195,90|keys={w_search_q}|wait=800"),
    ("stats.png", "projects/stats.dart?lang={w_lang}", ""),
    ("sorted.png", "projects/sorted.dart?lang={w_lang}", "button={w_sort}|menuitem={w_az}"),
]

TESTS = [
    ("model-test.sh", "test/model_test.dart"),
    ("app-test.sh", "test/app_test.dart"),
    ("projects/sorted-test.sh", "test/sorted_test.dart"),
    ("projects/sqlite-store-test.sh", "test/sqlite_store_test.dart"),
]


def main():
    flutter_gallery(
        HERE, T, FILES, SHOTS, TESTS,
        packages=["'flutter_localizations:{\"sdk\":\"flutter\"}'", "intl:any", "provider", "shared_preferences",
                  "sqflite", "dev:sqflite_common_ffi"],
        flutter_lines=["generate: true"],
        setup=[("gen-l10n.sh", "flutter gen-l10n")],
    )


if __name__ == "__main__":
    main()
