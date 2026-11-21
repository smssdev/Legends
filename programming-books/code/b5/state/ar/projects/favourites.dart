import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => Favourites(),
      child: MaterialApp(
        // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        debugShowCheckedModeBanner: false,
        home: const Shell(),
      ),
    ),
  );
}

const names = ['لاتيه', 'شاي بالنعناع', 'عصير برتقال', 'كيك الكرز'];

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
      appBar: AppBar(title: Text(tab == 0 ? 'كل المشروبات' : 'المفضلة')),
      body: shown.isEmpty
          ? const Center(child: Text('اضغط قلباً لتحفظ مشروباً هنا'))
          : ListView(
              children: [
                for (final name in shown)
                  ListTile(
                    title: Text(name),
                    trailing: IconButton(
                      tooltip: favs.contains(name)
                          ? 'ألغِ الإعجاب $name'
                          : 'أعجبني $name',
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
            label: 'كل المشروبات',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: favs.names.isNotEmpty,
              label: Text('${favs.names.length}'),
              child: const Icon(Icons.favorite),
            ),
            label: 'المفضلة',
          ),
        ],
      ),
    );
  }
}
