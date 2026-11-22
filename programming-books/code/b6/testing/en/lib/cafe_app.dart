import 'package:material_ui/material_ui.dart';

import 'data/demo_menu.dart';
import 'data/menu.dart';
import 'ui/menu_screen.dart';

class BitApp extends StatelessWidget {
  const BitApp({super.key, required this.repository, this.now = DateTime.now});

  final MenuRepository repository;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(colorSchemeSeed: Colors.brown),
      home: MenuScreen(repository: repository, now: now),
    );
  }
}

void main() => runApp(BitApp(repository: DemoMenu()));
