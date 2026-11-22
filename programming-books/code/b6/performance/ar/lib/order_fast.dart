import 'package:material_ui/material_ui.dart';

import 'rows.dart';

// سريع: الشارة وحدها تستمع إلى العدد.
class FastOrderPage extends StatefulWidget {
  const FastOrderPage({super.key});

  @override
  State<FastOrderPage> createState() => _FastOrderPageState();
}

class _FastOrderPageState extends State<FastOrderPage> {
  final count = ValueNotifier(0);

  @override
  void dispose() {
    count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبك'),
        actions: [
          ValueListenableBuilder(
            valueListenable: count,
            builder: (context, value, child) =>
                Badge.count(count: value, child: child),
            child: const Icon(Icons.local_cafe),
          ),
        ],
      ),
      body: const DrinkColumn(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => count.value++,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// القائمة لا تعتمد على العدد: تُبنى مرة ثم تُترك.
class DrinkColumn extends StatelessWidget {
  const DrinkColumn({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(children: [for (var n = 1; n <= 30; n++) DrinkRow(n: n)]),
  );
}
