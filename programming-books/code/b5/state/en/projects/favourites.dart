import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => Favourites(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const Shell(),
      ),
    ),
  );
}

const names = ['Latte', 'Mint tea', 'Orange juice', 'Cherry cake'];

class Favourites extends ChangeNotifier {
  final Set<String> _names = {};
  Set<String> get names => Set.unmodifiable(_names);
  bool contains(String name) => _names.contains(name);

  void toggle(String name) {
    _names.contains(name) ? _names.remove(name) : _names.add(name);
    notifyListeners();
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final favs = context.watch<Favourites>();
    final shown = tab == 0
        ? names
        : [
            for (final n in names)
              if (favs.contains(n)) n,
          ];
    return Scaffold(
      appBar: AppBar(title: Text(tab == 0 ? 'All drinks' : 'Favourites')),
      body: shown.isEmpty
          ? const Center(child: Text('Tap a heart to keep a drink here'))
          : ListView(
              children: [
                for (final name in shown)
                  ListTile(
                    title: Text(name),
                    trailing: IconButton(
                      tooltip: favs.contains(name)
                          ? 'Unlike $name'
                          : 'Like $name',
                      icon: Icon(
                        favs.contains(name)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.red,
                      ),
                      onPressed: () => context.read<Favourites>().toggle(name),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.local_cafe),
            label: 'All drinks',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: favs.names.isNotEmpty,
              label: Text('${favs.names.length}'),
              child: const Icon(Icons.favorite),
            ),
            label: 'Favourites',
          ),
        ],
      ),
    );
  }
}
