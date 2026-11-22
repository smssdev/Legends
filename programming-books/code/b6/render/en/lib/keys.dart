import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
      home: const KeysPage(),
    ),
  );
}

class Tile extends StatefulWidget {
  const Tile({super.key, required this.label});

  final String label;

  @override
  State<Tile> createState() => _TileState();
}

class _TileState extends State<Tile> {
  var taps = 0;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: InkWell(
          onTap: () => setState(() => taps++),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text('Tap: $taps'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class KeysPage extends StatefulWidget {
  const KeysPage({super.key});

  @override
  State<KeysPage> createState() => _KeysPageState();
}

class _KeysPageState extends State<KeysPage> {
  var labels = ['A', 'B'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keys')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Without keys', style: Theme.of(context).textTheme.titleMedium),
          // No key: after a swap, each State stays at its position.
          Row(children: [for (final l in labels) Tile(label: l)]),
          const SizedBox(height: 24),
          Text('With ValueKey', style: Theme.of(context).textTheme.titleMedium),
          // A key: each State follows its widget.
          Row(
            children: [
              for (final l in labels) Tile(key: ValueKey(l), label: l),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => setState(() => labels = labels.reversed.toList()),
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Swap'),
          ),
        ],
      ),
    );
  }
}
