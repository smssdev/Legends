import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'delegates.dart';
import 'l10n/app_localizations.dart';
import 'notes/model.dart';
import 'notes/note.dart';
import 'notes/store.dart';

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

enum Sort { newest, oldest, az }

// A pure function: the same notes and the same order always give the same list.
List<Note> sortNotes(List<Note> notes, Sort sort) {
  final sorted = [...notes];
  switch (sort) {
    case Sort.newest:
      sorted.sort((a, b) => b.edited.compareTo(a.edited));
    case Sort.oldest:
      sorted.sort((a, b) => a.edited.compareTo(b.edited));
    case Sort.az:
      // compareTo on strings is fine for English; for Arabic, see the hint.
      sorted.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
  }
  return sorted;
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => NotesModel(MemoryNotesStore(samples))..load(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        localizationsDelegates: delegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(colorSchemeSeed: Colors.brown),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.brown,
          brightness: Brightness.dark,
        ),
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
            tooltip: 'Sort',
            icon: const Icon(Icons.sort),
            initialValue: sort,
            onSelected: (s) => setState(() => sort = s),
            itemBuilder: (context) => const [
              PopupMenuItem(value: Sort.newest, child: Text('Newest first')),
              PopupMenuItem(value: Sort.oldest, child: Text('Oldest first')),
              PopupMenuItem(value: Sort.az, child: Text('A to Z')),
            ],
          ),
        ],
      ),
      body: ListView(
        children: [
          for (final n in notes)
            ListTile(title: Text(n.title), subtitle: Text(l.edited(n.edited))),
        ],
      ),
    );
  }
}
