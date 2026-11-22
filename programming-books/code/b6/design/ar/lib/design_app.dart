import 'package:material_ui/material_ui.dart';

import 'design/theme.dart';
import 'screens/catalog_screen.dart';
import 'screens/menu_screen.dart';

void main() => runApp(const DesignApp());

class DesignApp extends StatefulWidget {
  const DesignApp({super.key});

  @override
  State<DesignApp> createState() => _DesignAppState();
}

class _DesignAppState extends State<DesignApp> {
  var dark = false;
  var page = 0;

  @override
  Widget build(BuildContext context) {
    final actions = [
      Semantics(
        label: 'داكن',
        child: Switch(value: dark, onChanged: (v) => setState(() => dark = v)),
      ),
    ];
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),

      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        body: [
          MenuScreen(actions: actions),
          CatalogScreen(actions: actions),
        ][page],
        bottomNavigationBar: NavigationBar(
          selectedIndex: page,
          onDestinationSelected: (i) => setState(() => page = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.local_cafe),
              label: 'القائمة',
            ),
            NavigationDestination(icon: Icon(Icons.widgets), label: 'المكونات'),
          ],
        ),
      ),
    );
  }
}
