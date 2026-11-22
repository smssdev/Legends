import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      // من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),

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
                Text('المس: $taps'),
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
      appBar: AppBar(title: const Text('المفاتيح')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('بلا مفاتيح', style: Theme.of(context).textTheme.titleMedium),
          // بلا مفتاح: بعد التبديل تبقى كل State في موضعها.
          Row(children: [for (final l in labels) Tile(label: l)]),
          const SizedBox(height: 24),
          Text('مع ValueKey', style: Theme.of(context).textTheme.titleMedium),
          // مع مفتاح: كل State تتبع الـ Widget الخاص بها.
          Row(
            children: [
              for (final l in labels) Tile(key: ValueKey(l), label: l),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => setState(() => labels = labels.reversed.toList()),
            icon: const Icon(Icons.swap_horiz),
            label: const Text('بدّل'),
          ),
        ],
      ),
    );
  }
}
