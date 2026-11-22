import 'package:material_ui/material_ui.dart';

import 'config.dart';

void main() => runApp(const CafeApp());

class CafeApp extends StatelessWidget {
  const CafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Bit Café',
      theme: ThemeData(
        colorSchemeSeed: AppConfig.isProduction ? Colors.brown : Colors.indigo,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Menu')),
        body: ListView(
          children: [
            const ListTile(
              leading: Icon(Icons.dns),
              title: Text('Server'),
              subtitle: Text(AppConfig.apiUrl),
            ),
            const ListTile(
              leading: Icon(Icons.layers),
              title: Text('Build'),
              subtitle: Text(AppConfig.flavor),
            ),
            if (AppConfig.showDebug)
              const ListTile(
                leading: Icon(Icons.bug_report),
                title: Text('Debug tools are on'),
              ),
          ],
        ),
      ),
    );
    // Every build that is not production says so, in a corner no one can miss and nothing else uses.
    return AppConfig.isProduction
        ? app
        : Directionality(
            textDirection: TextDirection.ltr,
            child: Banner(
              message: AppConfig.flavor.toUpperCase(),
              location: BannerLocation.bottomEnd,
              child: app,
            ),
          );
  }
}
