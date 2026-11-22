import 'package:material_ui/material_ui.dart';

import 'design/brands.dart';
import 'design/theme.dart';
import 'screens/menu_screen.dart';

void main() => runApp(const BrandsApp());

class BrandsApp extends StatefulWidget {
  const BrandsApp({super.key});

  @override
  State<BrandsApp> createState() => _BrandsAppState();
}

class _BrandsAppState extends State<BrandsApp> {
  var bakery = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: bakery
          ? buildTheme(Brightness.light, brand: bakeryLight, seed: bakerySeed)
          : buildTheme(Brightness.light),
      home: MenuScreen(
        actions: [
          TextButton(
            onPressed: () => setState(() => bakery = !bakery),
            child: Text(bakery ? 'Bit Bakery' : 'Bit Café'),
          ),
        ],
      ),
    );
  }
}
