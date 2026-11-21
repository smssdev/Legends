import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp.router(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
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

// لكل شاشة عنوان، كالموقع.
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MenuPage(),
      routes: [
        // :id معامل: /drinks/2 تعرض المشروب رقم 2.
        GoRoute(
          path: 'drinks/:id',
          builder: (context, state) =>
              DrinkPage(index: int.parse(state.pathParameters['id']!)),
        ),
      ],
    ),
  ],
);

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('القائمة')),
      body: ListView(
        children: [
          for (var i = 0; i < drinks.length; i++)
            ListTile(
              title: Text(drinks[i].name),
              // go: غيّر العنوان؛ ويعرض الموجّه صفحته.
              onTap: () => context.go('/drinks/$i'),
            ),
        ],
      ),
    );
  }
}

class DrinkPage extends StatelessWidget {
  const DrinkPage({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final drink = drinks[index];
    return Scaffold(
      appBar: AppBar(title: Text(drink.name)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(drink.image, height: 240, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(drink.description),
          ),
        ],
      ),
    );
  }
}
