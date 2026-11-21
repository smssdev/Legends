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
              // push تضع صفحة جديدة في الأعلى؛ ويحصل الشريط على زر رجوع وحده.
              onTap: () => Navigator.push(
                context,
                // MaterialPageRoute: الصفحة، بحركة الانتقال الخاصة بالمنصة.
                MaterialPageRoute(
                  builder: (context) => DrinkPage(drink: drink),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DrinkPage extends StatelessWidget {
  const DrinkPage({super.key, required this.drink});

  final Drink drink;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(drink.name)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(drink.image, height: 240, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(
                  drink.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(drink.description),
                Text(
                  '${drink.price} جنيه',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
