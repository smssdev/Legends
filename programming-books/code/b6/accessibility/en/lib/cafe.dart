import 'package:material_ui/material_ui.dart';

const drinks = [
  ('Latte', 'Espresso and steamed milk', 45),
  ('Mint tea', 'Fresh mint, lightly sweet', 30),
  ('Cherry cake', 'Baked this morning', 55),
];

// Text at the size the person chose; the screenshots use 2 to show large text.
Widget cafe(Widget home, {double textScale = 1}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(colorSchemeSeed: Colors.brown),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: home,
);
