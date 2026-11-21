import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: const MenuPage()),
  );
}

Future<List<Map<String, dynamic>>> fetchMenu() async {
  final response = await http.get(Uri.parse('http://localhost:8080/menu'));
  if (response.statusCode != 200) {
    throw Exception('HTTP ${response.statusCode}');
  }
  return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
}

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  late final Future<List<Map<String, dynamic>>> menu = fetchMenu();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      // FutureBuilder shows each moment of a Future: waiting, an error, or the data.
      body: FutureBuilder(
        future: menu,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          return ListView(
            children: [
              for (final drink in snapshot.data!)
                ListTile(
                  title: Text(drink['name'] as String),
                  trailing: Text('${drink['price']} EGP'),
                ),
            ],
          );
        },
      ),
    );
  }
}
