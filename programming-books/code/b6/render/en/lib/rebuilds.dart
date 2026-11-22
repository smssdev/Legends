import 'package:material_ui/material_ui.dart';

// Counts how many times each widget's build method ran.
final builds = <String, int>{};

int counted(String name) => builds[name] = (builds[name] ?? 0) + 1;

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,

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
      appBar: AppBar(title: const Text('State in the page')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('RebuildsPage'),
            trailing: Text('$page builds'),
          ),
          // const: the same object every time, so Flutter skips it.
          const Badge1(),
          // Not const: a new object on every build of its parent, so it builds again.
          Badge2(),
          FilledButton(
            onPressed: () => setState(() => count++),
            child: Text('Add one ($count)'),
          ),
          const Divider(height: 32),
          Text(
            'State pushed down',
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
    trailing: Text('${counted('const')} builds'),
  );
}

class Badge2 extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  Badge2({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
    title: const Text('Badge2'),
    trailing: Text('${counted('plain')} builds'),
  );
}

// Its own state: setState here rebuilds only this widget.
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
          trailing: Text('$mine builds'),
        ),
        OutlinedButton(
          onPressed: () => setState(() => count++),
          child: Text('Add one ($count)'),
        ),
      ],
    );
  }
}
