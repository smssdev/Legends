import 'package:material_ui/material_ui.dart';

import 'brand.dart';
import 'tokens.dart';

ThemeData buildTheme(
  Brightness brightness, {
  Brand? brand,
  Color seed = const Color(0xFF6D4C41),
}) {
  // Material تبني مخططاً كاملاً سهل القراءة من لون بذرة واحد.
  final colors = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Radii.m),
  );
  return ThemeData(
    colorScheme: colors,
    extensions: [
      brand ?? (brightness == Brightness.light ? Brand.light : Brand.dark),
    ],
    // المكونات تأخذ أشكالها من الرموز مرة واحدة، هنا، لا في كل شاشة.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: shape,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: Space.l),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: shape,
        minimumSize: const Size(0, 48),
      ),
    ),
    cardTheme: CardThemeData(shape: shape, margin: EdgeInsets.zero),
  );
}
