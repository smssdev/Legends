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

// البيانات: كائن لكل مشروب، في قائمة const.
const drinks = [
  Drink('لاتيه', 'إسبريسو وحليب مُبخَّر', 45, 'assets/images/latte.png'),
  Drink('شاي بالنعناع', 'شاي أسود بنعناع طازج', 25, 'assets/images/tea.png'),
  Drink('عصير برتقال', 'معصور طازجاً', 40, 'assets/images/juice.png'),
  Drink('كيك الكرز', 'إسفنج ومربى وكريمة', 60, 'assets/images/cake.png'),
  Drink('كوكيز', 'بقطع الشوكولاتة', 20, 'assets/images/cookie.png'),
  Drink('مافن', 'بالشوكولاتة، مخبوز اليوم', 35, 'assets/images/muffin.png'),
];

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  // المشروبات التي يحبها الزبون: Set، كل اسم مرة واحدة.
  final favourites = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('القائمة · ${favourites.length} مفضلة')),
      // separated: فاصل بين كل عنصرين، ولا فاصل بعد الأخير.
      body: ListView.separated(
        itemCount: drinks.length,
        separatorBuilder: (context, i) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final drink = drinks[i];
          final liked = favourites.contains(drink.name);
          return ListTile(
            // صورة من التطبيق نفسه، مذكورة في pubspec.yaml.
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                drink.image,
                width: 64,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(drink.name),
            subtitle: Text('${drink.description} · ${drink.price} جنيه'),
            trailing: IconButton(
              icon: Icon(
                liked ? Icons.favorite : Icons.favorite_border,
                color: Colors.red,
              ),
              onPressed: () => setState(() {
                liked
                    ? favourites.remove(drink.name)
                    : favourites.add(drink.name);
              }),
            ),
          );
        },
      ),
    );
  }
}
