import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: const CafePage(),
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

class CafePage extends StatefulWidget {
  const CafePage({super.key});

  @override
  State<CafePage> createState() => _CafePageState();
}

class _CafePageState extends State<CafePage> {
  // السلة تعيش في الأب؛ وكل من الابنين يأخذها، ويأخذ طريقة لتغييرها.
  final basket = <Drink>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('القائمة')),
      body: DrinkList(onAdd: (drink) => setState(() => basket.add(drink))),
      bottomNavigationBar: BasketBar(basket: basket),
    );
  }
}

class DrinkList extends StatelessWidget {
  const DrinkList({super.key, required this.onAdd});

  // القائمة لا تملك السلة: إنها تستدعي من فوقها.
  final ValueChanged<Drink> onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final drink in drinks)
          ListTile(
            title: Text(drink.name),
            subtitle: Text('${drink.price} جنيه'),
            trailing: IconButton(
              tooltip: 'أضف ${drink.name}',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => onAdd(drink),
            ),
          ),
      ],
    );
  }
}

class BasketBar extends StatelessWidget {
  const BasketBar({super.key, required this.basket});

  final List<Drink> basket;

  @override
  Widget build(BuildContext context) {
    final total = basket.fold(0, (sum, d) => sum + d.price);
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.all(20),
      child: Text(
        '${basket.length} قطع · الإجمالي $total جنيه',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
