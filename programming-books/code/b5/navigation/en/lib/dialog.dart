import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: const OrdersPage()),
  );
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final orders = [101, 102, 103];

  Future<void> delete(int order) async {
    // showDialog is a route too: it waits for the answer, true or false.
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this order?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (sure == true) setState(() => orders.remove(order));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: ListView(
        children: [
          for (final order in orders)
            ListTile(
              title: Text('Order $order'),
              trailing: IconButton(
                tooltip: 'Delete order',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => delete(order),
              ),
            ),
        ],
      ),
    );
  }
}
