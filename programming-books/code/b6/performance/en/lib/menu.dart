import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,

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
      appBar: AppBar(title: const Text('Menu')),
      // Only the rows on screen, and a few around them, are ever built.
      body: ListView.builder(
        itemCount: 1000,
        itemExtent: 72,
        itemBuilder: (context, i) => ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            // Decode the photo at the size it is shown, not at the size it was taken.
            child: Image.asset(
              'assets/photos/latte.jpg',
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              cacheWidth: width,
            ),
          ),
          title: Text('Drink ${i + 1}'),
          trailing: Text('${40 + i % 5 * 5} EGP'),
        ),
      ),
    );
  }
}
