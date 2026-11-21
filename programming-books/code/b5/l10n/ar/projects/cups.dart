import 'package:material_ui/material_ui.dart';

import 'delegates.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: delegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('ar'),
      home: CupsPage(),
    ),
  );
}

class CupsPage extends StatefulWidget {
  const CupsPage({super.key});

  @override
  State<CupsPage> createState() => _CupsPageState();
}

class _CupsPageState extends State<CupsPage> {
  var cups = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.appTitle)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 24,
          children: [
            Text(l.cups(cups), style: Theme.of(context).textTheme.displaySmall),
            FilledButton.icon(
              onPressed: () => setState(() => cups++),
              icon: const Icon(Icons.coffee),
              label: Text(l.oneMore),
            ),
          ],
        ),
      ),
    );
  }
}
