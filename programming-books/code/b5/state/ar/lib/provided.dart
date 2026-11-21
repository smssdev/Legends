import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'basket.dart';

void main() {
  runApp(
    // قدّم سلة واحدة فوق التطبيق كله.
    ChangeNotifierProvider(
      create: (context) => Basket(),
      child: MaterialApp(
        // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        debugShowCheckedModeBanner: false,
        home: const MenuPage(),
      ),
    ),
  );
}

class Drink {
  const Drink(this.name, this.price);

  final String name;
  final int price;
}

const drinks = [
  Drink('لاتيه', 45),
  Drink('شاي بالنعناع', 25),
  Drink('عصير برتقال', 40),
  Drink('كيك الكرز', 60),
];

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('القائمة'),
        actions: const [BasketButton()],
      ),
      body: ListView(
        children: [
          for (final drink in drinks)
            ListTile(
              title: Text(drink.name),
              subtitle: Text('${drink.price} جنيه'),
              trailing: IconButton(
                tooltip: 'أضف ${drink.name}',
                icon: const Icon(Icons.add_circle_outline),
                // read: استخدم السلة مرة، دون استماع (في الدوال المستدعاة).
                onPressed: () =>
                    context.read<Basket>().add(drink.name, drink.price),
              ),
            ),
        ],
      ),
    );
  }
}

class BasketButton extends StatelessWidget {
  const BasketButton({super.key});

  @override
  Widget build(BuildContext context) {
    // select: أعد البناء فقط حين يتغير هذا الرقم وحده.
    final count = context.select<Basket, int>((b) => b.count);
    return IconButton(
      tooltip: 'السلة',
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BasketPage()),
      ),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.shopping_bag),
      ),
    );
  }
}

class BasketPage extends StatelessWidget {
  const BasketPage({super.key});

  @override
  Widget build(BuildContext context) {
    // watch: اقرأ السلة، وأعد البناء حين تتغير.
    final basket = context.watch<Basket>();
    return Scaffold(
      appBar: AppBar(title: const Text('السلة')),
      body: basket.count == 0
          ? const Center(child: Text('سلتك فارغة'))
          : ListView(
              children: [
                for (final MapEntry(key: name, value: n)
                    in basket.counts.entries)
                  ListTile(
                    title: Text('$n × $name'),
                    trailing: IconButton(
                      tooltip: 'احذف $name',
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => basket.remove(name),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: basket.count == 0 ? null : () {},
          child: Text('إتمام الطلب · ${basket.total} جنيه'),
        ),
      ),
    );
  }
}
