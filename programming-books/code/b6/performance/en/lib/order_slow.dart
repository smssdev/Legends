import 'package:material_ui/material_ui.dart';

import 'rows.dart';

// Slow: the whole page is rebuilt for one number.
class SlowOrderPage extends StatefulWidget {
  const SlowOrderPage({super.key});

  @override
  State<SlowOrderPage> createState() => _SlowOrderPageState();
}

class _SlowOrderPageState extends State<SlowOrderPage> {
  var count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your order'),
        actions: [
          Badge.count(count: count, child: const Icon(Icons.local_cafe)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(children: [for (var n = 1; n <= 30; n++) DrinkRow(n: n)]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => count++),
        child: const Icon(Icons.add),
      ),
    );
  }
}
