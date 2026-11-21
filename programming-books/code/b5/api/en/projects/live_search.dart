import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import 'cafe_api.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SearchPage(api: CafeApi(http.Client())),
    ),
  );
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.api});

  final CafeApi api;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  Timer? wait;
  List<Drink>? results;
  int asked = 0;

  void changed(String text) {
    // Wait 400 milliseconds after the last key before asking the server.
    wait?.cancel();
    wait = Timer(const Duration(milliseconds: 400), () async {
      asked++;
      final found = await widget.api.menu(query: text.trim());
      if (mounted) setState(() => results = found);
    });
  }

  @override
  void dispose() {
    wait?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final found = results;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          onChanged: changed,
          decoration: const InputDecoration(
            hintText: 'Search the menu',
            border: InputBorder.none,
          ),
        ),
      ),
      body: found == null
          ? const SizedBox()
          : found.isEmpty
          ? const Center(child: Text('No drink matches'))
          : ListView(
              children: [
                for (final d in found)
                  ListTile(
                    title: Text(d.name),
                    trailing: Text('${d.price} EGP'),
                  ),
              ],
            ),
    );
  }
}
