import 'package:material_ui/material_ui.dart';

import 'brand.dart';
import 'tokens.dart';

ThemeData buildTheme(
  Brightness brightness, {
  Brand? brand,
  Color seed = const Color(0xFF6D4C41),
}) {
  // Material builds a full, accessible scheme from one seed colour.
  final colors = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Radii.m),
  );
  return ThemeData(
    colorScheme: colors,
    extensions: [
      brand ?? (brightness == Brightness.light ? Brand.light : Brand.dark),
    ],
    // Components take their shapes from the tokens once, here, not in every screen.
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
