import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'delegates.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: delegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('en'),
      home: ReceiptPage(),
    ),
  );
}

final paid = DateTime(2026, 12, 3, 9, 41);
const total = 1250;

// ar_EG writes Eastern Arabic digits; ar alone keeps 0 to 9.
String totalIn(String locale) => NumberFormat.currency(
  locale: locale,
  name: 'EGP',
  decimalDigits: 0,
).format(total);
String timeIn(String locale) => DateFormat.yMMMd(locale).add_jm().format(paid);

class ReceiptPage extends StatelessWidget {
  const ReceiptPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final locale in ['en', 'ar', 'ar_EG'])
            Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(locale.split('_').first)),
                title: Text(
                  totalIn(locale),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: Text('$locale · ${timeIn(locale)}'),
              ),
            ),
        ],
      ),
    );
  }
}
