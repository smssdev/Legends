import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: const Shell()));
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int page = 0;

  static const titles = ['Menu', 'Orders', 'Account'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titles[page])),
      // A drawer slides in from the start edge.
      drawer: Drawer(
        child: ListView(
          children: const [
            DrawerHeader(
              child: Align(
                alignment: AlignmentDirectional.bottomStart,
                child: Text('Signed in as Sara'),
              ),
            ),
            ListTile(leading: Icon(Icons.settings), title: Text('Settings')),
            ListTile(leading: Icon(Icons.help_outline), title: Text('Help')),
          ],
        ),
      ),
      // IndexedStack keeps every page alive, so each keeps its scroll and its state.
      body: IndexedStack(
        index: page,
        children: const [
          Center(child: Icon(Icons.local_cafe, size: 96)),
          Center(child: Text('No orders yet')),
          Center(child: Icon(Icons.person, size: 96)),
        ],
      ),
      // The bar at the bottom chooses which page the body shows.
      bottomNavigationBar: NavigationBar(
        selectedIndex: page,
        onDestinationSelected: (i) => setState(() => page = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.local_cafe), label: 'Menu'),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}
