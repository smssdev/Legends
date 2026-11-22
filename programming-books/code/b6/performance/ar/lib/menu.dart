import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      // من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),

      theme: ThemeData(colorSchemeSeed: Colors.brown),
      home: const MenuPage(),
    ),
  );
}

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = (56 * MediaQuery.devicePixelRatioOf(context)).round();
    return Scaffold(
      appBar: AppBar(title: const Text('القائمة')),
      // لا يُبنى إلا ما على الشاشة من صفوف، وقليل حولها.
      body: ListView.builder(
        itemCount: 1000,
        itemExtent: 72,
        itemBuilder: (context, i) => ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            // فُكّ الصورة بالحجم الذي تُعرض به، لا بالحجم الذي التُقطت به.
            child: Image.asset(
              'assets/photos/latte.jpg',
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              cacheWidth: width,
            ),
          ),
          title: Text('مشروب ${i + 1}'),
          trailing: Text('${40 + i % 5 * 5} جنيه'),
        ),
      ),
    );
  }
}
