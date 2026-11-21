import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const ThemesApp());
}

class ThemesApp extends StatefulWidget {
  const ThemesApp({super.key});

  @override
  State<ThemesApp> createState() => _ThemesAppState();
}

class _ThemesAppState extends State<ThemesApp> {
  bool dark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      // سمتان من البذرة نفسها: فاتحة وداكنة.
      theme: ThemeData(colorSchemeSeed: Colors.brown),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.brown,
        brightness: Brightness.dark,
      ),
      // themeMode تختار أيهما يُستخدم.
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        appBar: AppBar(title: const Text('مقهى بِت')),
        body: ListView(
          children: [
            SwitchListTile(
              title: const Text('الوضع الداكن'),
              secondary: const Icon(Icons.dark_mode),
              value: dark,
              onChanged: (value) => setState(() => dark = value),
            ),
            const Divider(),
            for (final drink in drinks)
              ListTile(
                leading: CircleAvatar(backgroundImage: AssetImage(drink.image)),
                title: Text(drink.name),
                trailing: Text('${drink.price} جنيه'),
              ),
          ],
        ),
      ),
    );
  }
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
