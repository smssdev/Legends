import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      // من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),

      theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
      home: const ConstraintsPage(),
    ),
  );
}

String describe(BoxConstraints c) {
  String range(double min, double max) => min == max
      ? min.toStringAsFixed(0)
      : '${min.toStringAsFixed(0)}–${max.isFinite ? max.toStringAsFixed(0) : '∞'}';
  return 'w ${range(c.minWidth, c.maxWidth)}   h ${range(c.minHeight, c.maxHeight)}';
}

// يعرض القيود التي تلقّاها هذا المكان من أبيه.
class ConstraintsLabel extends StatelessWidget {
  const ConstraintsLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ColoredBox(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(describe(constraints), textDirection: TextDirection.ltr),
        ),
      ),
    );
  }
}

class ConstraintsPage extends StatelessWidget {
  const ConstraintsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final examples = [
      (
        'داخل SizedBox(300 × 56)',
        const SizedBox(width: 300, height: 56, child: ConstraintsLabel()),
      ),
      (
        'داخل Center، داخل الصندوق نفسه',
        const SizedBox(
          width: 300,
          height: 56,
          child: Center(child: ConstraintsLabel()),
        ),
      ),
      (
        'داخل Expanded، في Row',
        const Row(
          children: [
            Expanded(child: ConstraintsLabel()),
            SizedBox(width: 120),
          ],
        ),
      ),
      (
        'داخل ListView عمودية',
        SizedBox(
          height: 56,
          child: ListView(children: const [ConstraintsLabel()]),
        ),
      ),
      (
        'Container(width: 100) في 300 صارمة',
        SizedBox(
          width: 300,
          height: 56,
          // يطلب عرض 100، لكن الأب صارم: فيأخذ 300.
          child: Container(
            width: 100,
            color: Colors.amber,
            child: const ConstraintsLabel(),
          ),
        ),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('القيود')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (label, child) in examples) ...[
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Align(alignment: AlignmentDirectional.centerStart, child: child),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
