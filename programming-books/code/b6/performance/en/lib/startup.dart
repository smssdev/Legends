import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'menu.dart';

// Stand-ins for real work: reading settings, opening the database, fetching the menu.
Future<void> readSettings() =>
    Future.delayed(const Duration(milliseconds: 300));
Future<void> openDatabase() =>
    Future.delayed(const Duration(milliseconds: 200));
Future<void> fetchMenu() => Future.delayed(const Duration(milliseconds: 400));

Future<void> startOneByOne() async {
  await readSettings();
  await openDatabase();
  await fetchMenu();
}

// The three steps do not depend on each other: start them together.
Future<void> startTogether() =>
    Future.wait([readSettings(), openDatabase(), fetchMenu()]).then((_) {});

// Show something at once; load the rest behind it.
void main() {
  final ready = startTogether();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(colorSchemeSeed: Colors.brown),
      home: FutureBuilder(
        future: ready,
        builder: (context, snapshot) =>
            snapshot.connectionState == ConnectionState.done
            ? const MenuPage()
            : const Splash(),
      ),
    ),
  );
}

class Splash extends StatelessWidget {
  const Splash({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [CircularProgressIndicator(), Text('Getting the menu ready')],
      ),
    ),
  );
}
