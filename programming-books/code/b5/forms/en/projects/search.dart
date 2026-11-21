import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: const SearchPage()),
  );
}

final drinks = 'Latte,Cappuccino,Mocha,Mint tea,Green tea,Orange juice,Lemonade,Hot chocolate'
    .split(',');

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final query = TextEditingController();

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = query.text.trim().toLowerCase();
    final found = [
      for (final d in drinks)
        if (d.toLowerCase().contains(words)) d,
    ];
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: query,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search the menu',
            border: InputBorder.none,
            suffixIcon: query.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(query.clear),
                  ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
      body: found.isEmpty
          ? const Center(child: Text('No drink matches'))
          : ListView(
              children: [
                for (final d in found)
                  ListTile(
                    leading: const Icon(Icons.local_cafe),
                    title: Text(d),
                  ),
              ],
            ),
    );
  }
}
