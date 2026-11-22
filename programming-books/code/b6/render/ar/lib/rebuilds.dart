import 'package:material_ui/material_ui.dart';

// يعدّ كم مرة نُفّذت دالة build في كل Widget.
final builds = <String, int>{};

int counted(String name) => builds[name] = (builds[name] ?? 0) + 1;

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      // من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),

      theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
      home: const RebuildsPage(),
    ),
  );
}

class RebuildsPage extends StatefulWidget {
  const RebuildsPage({super.key});

  @override
  State<RebuildsPage> createState() => _RebuildsPageState();
}

class _RebuildsPageState extends State<RebuildsPage> {
  var count = 0;

  @override
  Widget build(BuildContext context) {
    final page = counted('page');
    return Scaffold(
      appBar: AppBar(title: const Text('الحالة في الصفحة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('RebuildsPage'),
            trailing: Text('$page مرات البناء'),
          ),
          // const: الكائن نفسه في كل مرة، فيتخطاه Flutter.
          const Badge1(),
          // بلا const: كائن جديد مع كل بناء لأبيه، فيُبنى من جديد.
          Badge2(),
          FilledButton(
            onPressed: () => setState(() => count++),
            child: Text('أضف واحداً ($count)'),
          ),
          const Divider(height: 32),
          Text(
            'الحالة أُنزلت إلى أسفل',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const LocalCounter(),
        ],
      ),
    );
  }
}

class Badge1 extends StatelessWidget {
  const Badge1({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
    title: const Text('const Badge1'),
    trailing: Text('${counted('const')} مرات البناء'),
  );
}

class Badge2 extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  Badge2({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
    title: const Text('Badge2'),
    trailing: Text('${counted('plain')} مرات البناء'),
  );
}

// حالته الخاصة: setState هنا تعيد بناء هذا الـ Widget وحده.
class LocalCounter extends StatefulWidget {
  const LocalCounter({super.key});

  @override
  State<LocalCounter> createState() => _LocalCounterState();
}

class _LocalCounterState extends State<LocalCounter> {
  var count = 0;

  @override
  Widget build(BuildContext context) {
    final mine = counted('local');
    return Column(
      children: [
        ListTile(
          title: const Text('LocalCounter'),
          trailing: Text('$mine مرات البناء'),
        ),
        OutlinedButton(
          onPressed: () => setState(() => count++),
          child: Text('أضف واحداً ($count)'),
        ),
      ],
    );
  }
}
