import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: const HelloPage()),
  );
}

class HelloPage extends StatefulWidget {
  const HelloPage({super.key});

  @override
  State<HelloPage> createState() => _HelloPageState();
}

class _HelloPageState extends State<HelloPage> {
  // A controller holds the text of the field, and can read or change it.
  final name = TextEditingController();

  @override
  void dispose() {
    // Controllers must be released when the page goes away.
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final who = name.text.isEmpty ? 'stranger' : name.text;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 24,
          children: [
            TextField(
              controller: name,
              decoration: InputDecoration(
                labelText: 'Your name',
                hintText: 'As on your cup',
                prefixIcon: const Icon(Icons.person),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(name.clear),
                ),
              ),
              // onChanged runs on every key: rebuild, so the greeting follows.
              onChanged: (_) => setState(() {}),
            ),
            Text(
              'Hello $who!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}
