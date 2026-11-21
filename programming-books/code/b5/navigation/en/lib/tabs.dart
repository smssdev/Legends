import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: const TabsPage()),
  );
}

class TabsPage extends StatelessWidget {
  const TabsPage({super.key});

  Widget list(List<String> items) =>
      ListView(children: [for (final i in items) ListTile(title: Text(i))]);

  @override
  Widget build(BuildContext context) {
    // A TabBar and a TabBarView, kept in step by the controller.
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bit Café'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.local_cafe), text: 'Drinks'),
              Tab(icon: Icon(Icons.bakery_dining), text: 'Food'),
              Tab(icon: Icon(Icons.local_offer), text: 'Offers'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            list(['Latte', 'Mint tea', 'Orange juice']),
            list(['Cherry cake', 'Cookie', 'Muffin']),
            list(['Two lattes for 80', 'Free cookie on Fridays']),
          ],
        ),
      ),
    );
  }
}
