import 'package:material_ui/material_ui.dart';
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
      create: (context) =>
          NotesModel(PrefsNotesStore(SharedPreferencesAsync()))..load(),
      child: const NotesApp(),
    ),
  );
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: delegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(colorSchemeSeed: Colors.brown),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.brown,
        brightness: Brightness.dark,
      ),
      home: const NotesPage(),
    );
  }
}
