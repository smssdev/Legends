import 'package:material_ui/material_ui.dart';

import 'basket.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: CafePage(basket: Basket()),
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

class CafePage extends StatelessWidget {
  const CafePage({super.key, required this.basket});

  final Basket basket;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('القائمة')),
      body: ListView(
        children: [
          for (final drink in drinks)
            ListTile(
              title: Text(drink.name),
              subtitle: Text('${drink.price} جنيه'),
              trailing: IconButton(
                tooltip: 'أضف ${drink.name}',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => basket.add(drink.name, drink.price),
              ),
            ),
        ],
      ),
      // ListenableBuilder يعيد بناء دالته كلما أبلغت السلة.
      bottomNavigationBar: ListenableBuilder(
        listenable: basket,
        builder: (context, child) => Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          padding: const EdgeInsets.all(20),
          child: Text('${basket.count} قطع · الإجمالي ${basket.total} جنيه'),
        ),
      ),
    );
  }
}
