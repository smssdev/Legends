import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

import 'api/client.dart';
import 'api/errors.dart';
import 'api/messages.dart';

// A pretend server inside the app for this screen: busy twice, then it answers.
var calls = 0;
final flaky = MockClient((request) async {
  await Future<void>.delayed(const Duration(milliseconds: 150));
  if (++calls <= 2) {
    return http.Response('{"error": "busy"}', 503);
  }
  return http.Response(
    jsonEncode([
      {'name': 'Latte', 'price': 45},
      {'name': 'Mint tea', 'price': 25},
      {'name': 'Cherry cake', 'price': 60},
    ]),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
});

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const MenuPage(),
    ),
  );
}

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final lines = <String>[];
  late final api = ApiClient(
    flaky,
    base: 'https://cafe.example',
    random: Random(7),
    log: (l) => setState(() => lines.add(l)),
  );
  List<Object?>? menu;
  ApiError? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await api.get('/menu') as List<Object?>;
      setState(() => menu = result);
    } on ApiError catch (e) {
      setState(() => error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = this.error;
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (menu case final items?)
            for (final item in items.cast<Map<String, Object?>>())
              ListTile(
                title: Text('${item['name']}'),
                trailing: Text('${item['price']} EGP'),
              ),
          if (error != null)
            ListTile(
              leading: const Icon(Icons.cloud_off),
              title: Text(message(error)),
            ),
          if (menu == null && error == null) const LinearProgressIndicator(),
          const Divider(height: 32),
          Text('What happened', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final line in lines)
            Text(
              line,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
        ],
      ),
    );
  }
}
