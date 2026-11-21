import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: const OrdersPage(),
    ),
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
    // showDialog مسار أيضاً: ينتظر الإجابة، صحيح أو خطأ.
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('أتحذف هذا الطلب؟'),
        content: const Text('لا يمكن التراجع عن هذا.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('احذف'),
          ),
        ],
      ),
    );
    if (sure == true) setState(() => orders.remove(order));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الطلبات')),
      body: ListView(
        children: [
          for (final order in orders)
            ListTile(
              title: Text('طلب $order'),
              trailing: IconButton(
                tooltip: 'احذف الطلب',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => delete(order),
              ),
            ),
        ],
      ),
    );
  }
}
