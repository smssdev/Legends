import 'package:flutter/material.dart';

import 'tokens.g.dart';
import 'widgets/cut.dart';

/// [Sprint 15 F1, F2] The game's look in Flutter, from the same tokens as the web: the night (our own) and the day,
/// Tajawal for the words and Barlow Condensed for the numbers. Every colour comes from [GlmPalette]: no colour by hand.
class GlmColors extends ThemeExtension<GlmColors> {
  const GlmColors(this.p, {required this.day});

  final GlmPalette p;
  final bool day;

  /// An accent's text: by day the darker ink (4.5:1 on paper), at night the accent itself.
  Color get goldText => day ? GlmInk.gold : p.gold;
  Color get brandText => day ? GlmInk.brand : p.brandLight;
  Color get successText => day ? GlmInk.success : p.success;
  Color get liveText => day ? GlmInk.live : p.danger;

  @override
  GlmColors copyWith({GlmPalette? p, bool? day}) => GlmColors(p ?? this.p, day: day ?? this.day);

  @override
  GlmColors lerp(ThemeExtension<GlmColors>? other, double t) => t < .5 || other is! GlmColors ? this : other;
}

abstract final class GlmFonts {
  static const body = 'Tajawal';
  static const numbers = 'BarlowCondensed';
}

/// [Sprint 46] The app's night look on the arena (tokens.json «arena», the owner's choice): the royal-blue ground, navy
/// cards and panels, the rest of the night's colours kept (gold, pitch, the text, the states).
final glmArenaNight = GlmPalette(
  bg: GlmArena.blue, bgDeep: GlmArena.blueDeep, surface: GlmArena.navy, surfaceSunk: Color.lerp(GlmArena.navy, const Color(0xFF000000), .25)!,
  surfaceRaised: GlmArena.navyLight, gold: glmNight.gold, goldDark: glmNight.goldDark, goldLight: glmNight.goldLight, pitch: glmNight.pitch,
  pitchDark: glmNight.pitchDark, text: glmNight.text, textMuted: const Color(0xFFB9C7E3), textSoft: const Color(0xFFD6DFF0), live: glmNight.live,
  warning: glmNight.warning, success: glmNight.success, onGold: glmNight.onGold, brand: glmNight.brand, brandDark: GlmArena.blueDeep,
  brandLight: GlmArena.blueLight, ring: glmNight.ring, chrome: glmNight.chrome, chromeDark: glmNight.chromeDark, onChrome: glmNight.onChrome,
  panel: GlmArena.navy, danger: glmNight.danger, bronze: glmNight.bronze, silver: glmNight.silver, cardYellow: glmNight.cardYellow, shade: glmNight.shade,
);

ThemeData glmTheme({required bool day}) {
  final p = day ? glmDay : glmArenaNight;
  final scheme = ColorScheme(
    brightness: day ? Brightness.light : Brightness.dark,
    primary: p.gold, onPrimary: p.onGold,
    secondary: p.brand, onSecondary: Colors.white,
    error: p.live, onError: Colors.white,
    surface: p.surface, onSurface: p.text,
    surfaceContainerLowest: p.bgDeep, surfaceContainerLow: p.surfaceSunk, surfaceContainer: p.surface,
    surfaceContainerHigh: p.surfaceRaised, surfaceContainerHighest: p.surfaceRaised,
    onSurfaceVariant: p.textMuted, outline: p.surfaceRaised, outlineVariant: p.surfaceRaised, shadow: p.shade,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: GlmFonts.body, scaffoldBackgroundColor: p.bg);
  final text = base.textTheme.apply(bodyColor: p.text, displayColor: p.text, fontFamily: GlmFonts.body);

  return base.copyWith(
    extensions: [GlmColors(p, day: day)],
    textTheme: text.copyWith(
      displaySmall: text.displaySmall?.copyWith(fontWeight: FontWeight.w800),
      headlineMedium: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      bodyMedium: text.bodyMedium?.copyWith(height: 1.55),
      bodySmall: text.bodySmall?.copyWith(color: p.textMuted, height: 1.5),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w800),
    ),
    // [2026-11-06] Screens fade through into each other, as in a game's menus.
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
    }),
    appBarTheme: AppBarTheme(toolbarHeight: 50, backgroundColor: day ? p.panel : p.bgDeep, foregroundColor: p.text, elevation: 0, scrolledUnderElevation: 0, centerTitle: false,
        surfaceTintColor: Colors.transparent, titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 20)),
    // [2026-11-06] The league's five sections at the bottom, as in the manager games: gold for where you are.
    // In landscape the league's sections stand in a rail at the side.
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: day ? p.panel : p.bgDeep,
      indicatorColor: p.gold.withValues(alpha: day ? .22 : .18),
      selectedIconTheme: IconThemeData(color: day ? GlmInk.gold : p.gold, size: 24),
      unselectedIconTheme: IconThemeData(color: p.textMuted, size: 24),
      selectedLabelTextStyle: TextStyle(fontFamily: GlmFonts.body, fontSize: 12, fontWeight: FontWeight.w800, color: day ? GlmInk.gold : p.gold),
      unselectedLabelTextStyle: TextStyle(fontFamily: GlmFonts.body, fontSize: 12, fontWeight: FontWeight.w600, color: p.textMuted),
      labelType: NavigationRailLabelType.all,
      indicatorShape: GlmCut.shape(GlmCut.badge),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: day ? p.panel : p.bgDeep,
      surfaceTintColor: Colors.transparent,
      indicatorColor: p.gold.withValues(alpha: day ? .22 : .18),
      indicatorShape: GlmCut.shape(GlmCut.badge),
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(fontFamily: GlmFonts.body, fontSize: 12,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600, color: s.contains(WidgetState.selected) ? (day ? GlmInk.gold : p.gold) : p.textMuted)),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: s.contains(WidgetState.selected) ? (day ? GlmInk.gold : p.gold) : p.textMuted, size: 24)),
    ),
    tabBarTheme: TabBarThemeData(labelColor: day ? GlmInk.gold : p.gold, unselectedLabelColor: p.textMuted, indicatorColor: p.gold, dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontFamily: GlmFonts.body, fontWeight: FontWeight.w800, fontSize: 15)),
    chipTheme: ChipThemeData(backgroundColor: p.surface, side: BorderSide(color: p.surfaceRaised), shape: GlmCut.shape(GlmCut.badge),
        labelStyle: TextStyle(fontFamily: GlmFonts.body, fontWeight: FontWeight.w700, color: p.text)),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: day ? p.panel : p.surface, surfaceTintColor: Colors.transparent,
        shape: BeveledRectangleBorder(borderRadius: BorderRadiusDirectional.only(topStart: const Radius.circular(22), topEnd: const Radius.circular(5)))),
    listTileTheme: ListTileThemeData(iconColor: p.gold, titleTextStyle: TextStyle(fontFamily: GlmFonts.body, fontWeight: FontWeight.w700, fontSize: 15, color: p.text)),
    dividerTheme: DividerThemeData(color: p.surfaceRaised, thickness: 1),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: p.surfaceRaised,
        contentTextStyle: TextStyle(fontFamily: GlmFonts.body, color: p.text, fontWeight: FontWeight.w600),
        shape: GlmCut.shape(GlmCut.button)),
    // [2026-11-06] The Legend Cut on the dialogs, the segmented choices and the menus too.
    dialogTheme: DialogThemeData(backgroundColor: day ? p.panel : p.surface, surfaceTintColor: Colors.transparent, shape: GlmCut.shape(GlmCut.card)),
    segmentedButtonTheme: SegmentedButtonThemeData(style: ButtonStyle(shape: WidgetStatePropertyAll(GlmCut.shape(GlmCut.button)))),
    popupMenuTheme: PopupMenuThemeData(shape: GlmCut.shape(GlmCut.badge), color: p.surfaceRaised),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: p.surfaceSunk,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: TextStyle(color: p.textMuted),
      border: CutInputBorder(borderSide: BorderSide(color: p.surfaceRaised)),
      enabledBorder: CutInputBorder(borderSide: BorderSide(color: p.surfaceRaised)),
      focusedBorder: CutInputBorder(borderSide: BorderSide(color: p.gold, width: 2)),
      errorBorder: CutInputBorder(borderSide: BorderSide(color: p.live)),
      focusedErrorBorder: CutInputBorder(borderSide: BorderSide(color: p.live, width: 2)),
      errorStyle: TextStyle(color: day ? GlmInk.live : p.danger, fontWeight: FontWeight.w600),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.gold),
  );
}

extension GlmContext on BuildContext {
  GlmColors get glm => Theme.of(this).extension<GlmColors>()!;
  GlmPalette get palette => glm.p;
  TextTheme get text => Theme.of(this).textTheme;
}
