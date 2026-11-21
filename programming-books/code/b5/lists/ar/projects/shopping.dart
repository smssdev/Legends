import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: const ShoppingPage(),
    ),
  );
}

class ShoppingPage extends StatefulWidget {
  const ShoppingPage({super.key});

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  final items = 'حليب,حبوب قهوة,سكر,أكواب,مناديل,برتقال'.split(',');

  // اسحب العنصر جانباً لحذفه؛ والشريط السفلي يستطيع إعادته.
  void remove(int index) {
    final item = items[index];
    setState(() => items.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$item حُذف'),
        action: SnackBarAction(
          label: 'تراجع',
          onPressed: () => setState(() => items.insert(index, item)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('قائمة المشتريات (${items.length})')),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, i) => Dismissible(
          key: ValueKey(items[i]),
          background: Container(
            color: Colors.red,
            alignment: AlignmentDirectional.centerStart,
            padding: const EdgeInsetsDirectional.only(start: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) => remove(i),
          child: ListTile(
            leading: const Icon(Icons.shopping_basket),
            title: Text(items[i]),
          ),
        ),
      ),
    );
  }
}
