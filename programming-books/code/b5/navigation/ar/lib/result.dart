import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: const MenuPage(),
    ),
  );
}

class Drink {
  const Drink(this.name, this.description, this.price, this.image);

  final String name;
  final String description;
  final int price;
  final String image;
}

const drinks = [
  Drink('لاتيه', 'إسبريسو وحليب مُبخَّر', 45, 'assets/images/latte.png'),
  Drink('شاي بالنعناع', 'شاي أسود بنعناع طازج', 25, 'assets/images/tea.png'),
  Drink('عصير برتقال', 'معصور طازجاً', 40, 'assets/images/juice.png'),
  Drink('كيك الكرز', 'إسفنج ومربى وكريمة', 60, 'assets/images/cake.png'),
];

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  Future<void> open(BuildContext context, Drink drink) async {
    // push تُرجع Future: إجابة الصفحة، حين تُغلق.
    final count = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (context) => OrderPage(drink: drink)),
    );
    // null: رجع الزبون دون أن يضيف شيئاً.
    if (count == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('أُضيف $count × ${drink.name}')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('القائمة')),
      body: ListView(
        children: [
          for (final drink in drinks)
            ListTile(
              leading: CircleAvatar(backgroundImage: AssetImage(drink.image)),
              title: Text(drink.name),
              subtitle: Text('${drink.price} جنيه'),
              onTap: () => open(context, drink),
            ),
        ],
      ),
    );
  }
}

class OrderPage extends StatefulWidget {
  const OrderPage({super.key, required this.drink});

  final Drink drink;

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.drink.name)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(widget.drink.image, height: 240, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(widget.drink.description),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton.outlined(
                tooltip: 'أقل',
                onPressed: quantity > 1
                    ? () => setState(() => quantity--)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('$quantity', style: const TextStyle(fontSize: 22)),
              ),
              IconButton.outlined(
                tooltip: 'أكثر',
                onPressed: () => setState(() => quantity++),
                icon: const Icon(Icons.add),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  // pop تغلق هذه الصفحة وتعيد الإجابة.
                  onPressed: () => Navigator.pop(context, quantity),
                  child: Text('أضف $quantity إلى الطلب'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
