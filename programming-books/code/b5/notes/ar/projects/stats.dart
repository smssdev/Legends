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

// كل ما في هذه الصفحة محسوب من النموذج: لا شيء يُحفظ مرتين.
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
      (Icons.notes, 'الملاحظات', '${notes.length}'),
      (Icons.push_pin, 'المثبّتة', '${notes.where((n) => n.pinned).length}'),
      (
        Icons.short_text,
        'الكلمات',
        '${notes.fold(0, (sum, n) => sum + words(n))}',
      ),
      (Icons.straighten, 'أطول ملاحظة', longest?.title ?? '-'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('إحصاءات')),
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
