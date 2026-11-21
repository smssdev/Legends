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
        home: const StatsPage(),
      ),
    ),
  );
}

// Everything on this page is computed from the model: nothing is stored twice.
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NotesModel>().all;
    int words(Note n) => '${n.title} ${n.body}'
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    final longest = notes.isEmpty
        ? null
        : notes.reduce((a, b) => words(a) >= words(b) ? a : b);
    final rows = [
      (Icons.notes, 'Notes', '${notes.length}'),
      (Icons.push_pin, 'Pinned', '${notes.where((n) => n.pinned).length}'),
      (
        Icons.short_text,
        'Words',
        '${notes.fold(0, (sum, n) => sum + words(n))}',
      ),
      (Icons.straighten, 'Longest note', longest?.title ?? '-'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: ListView(
        children: [
          for (final (icon, label, value) in rows)
            ListTile(
              leading: Icon(icon),
              title: Text(label),
              trailing: Text(
                value,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
        ],
      ),
    );
  }
}
