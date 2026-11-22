"""Writes the examples of Book 6, chapter "Design Systems in Flutter", in English and Arabic: design tokens,
a ThemeExtension for the brand's own colours, light and dark themes, a few components built only from tokens,
a catalogue page, a contrast test (WCAG) and a guard test that keeps raw values out of screens.
Run: python3 make.py   (needs Flutter 3.50.1, Node.js and Playwright's Chromium)
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent.parent / "b5"))
from kit import flutter_gallery  # noqa: E402

T = {
    "en": dict(
        w_rtl="",
        w_catalog="Components", w_dark="Dark", w_menu="Menu", w_egp="EGP",
        w_buttons="Buttons", w_primary="Order", w_secondary="Details", w_tags="Tags", w_cards="Cards",
        w_ready="Ready", w_soon="Almost sold out", w_new="New", w_latte="Latte", w_tea="Mint tea", w_cake="Cherry cake",
        w_latte_d="Espresso and steamed milk", w_tea_d="Fresh mint, a little sugar", w_cake_d="Baked this morning",
        w_c_space="Spacing: one scale for every gap in the app.",
        w_c_radius="Corners: three sizes, nothing in between.",
        w_c_brand="The brand's own colours, next to Material's: a ThemeExtension travels with the theme.",
        w_c_pairs="Every colour comes with the colour of what is written on it.",
        w_c_lerp="lerp: how a colour moves between two themes, so that switching animates instead of jumping.",
        w_c_seed="Material builds a full, accessible scheme from one seed colour.",
        w_c_shapes="Components take their shapes from the tokens once, here, not in every screen.",
        w_c_context="Short names for screens: context.brand, context.colors, context.text.",
        w_c_button="One button for the whole app; screens choose what it means, not how it looks.",
        w_c_tag="A tag says one thing at a glance: its kind chooses the colours.",
        w_c_gap="A gap from the scale: screens never write a number.",
        w_c_screen="A real screen: nothing but components, tokens and the theme.",
        w_t_contrast="every colour pair is readable in both themes",
        w_t_bad="a pair that is not readable is caught",
        w_t_guard="screens use tokens, not raw values",
        w_t_guard_bad="a screen with raw values is caught",
        w_t_lerp="switching themes animates the brand colours too",
        w_t_brands="two brands, the same components, both readable",
        w_bakery="Bit Bakery", w_cafe="Bit Café",
    ),
    "ar": dict(
        w_rtl="// من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.\n"
              "builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),\n",
        w_catalog="المكونات", w_dark="داكن", w_menu="القائمة", w_egp="جنيه",
        w_buttons="الأزرار", w_primary="اطلب", w_secondary="التفاصيل", w_tags="الوسوم", w_cards="البطاقات",
        w_ready="جاهز", w_soon="أوشك أن ينفد", w_new="جديد", w_latte="لاتيه", w_tea="شاي بالنعناع", w_cake="كيك الكرز",
        w_latte_d="إسبريسو وحليب مبخّر", w_tea_d="نعناع طازج وقليل من السكر", w_cake_d="خُبز هذا الصباح",
        w_c_space="المسافات: مقياس واحد لكل فراغ في التطبيق.",
        w_c_radius="الزوايا: ثلاثة مقاسات، ولا شيء بينها.",
        w_c_brand="ألوان العلامة نفسها، بجانب ألوان Material: فـ ThemeExtension تسافر مع الثيم.",
        w_c_pairs="كل لون يأتي مع لون ما يُكتب عليه.",
        w_c_lerp="lerp: كيف ينتقل اللون بين ثيمين، فيتحرك التبديل بدل أن يقفز.",
        w_c_seed="Material تبني مخططاً كاملاً سهل القراءة من لون بذرة واحد.",
        w_c_shapes="المكونات تأخذ أشكالها من الرموز مرة واحدة، هنا، لا في كل شاشة.",
        w_c_context="أسماء قصيرة للشاشات: context.brand وcontext.colors وcontext.text.",
        w_c_button="زر واحد للتطبيق كله؛ والشاشات تختار ما يعنيه، لا كيف يبدو.",
        w_c_tag="الوسم يقول شيئاً واحداً بنظرة: ونوعه يختار الألوان.",
        w_c_gap="فراغ من المقياس: الشاشات لا تكتب رقماً أبداً.",
        w_c_screen="شاشة حقيقية: لا شيء غير المكونات والرموز والثيم.",
        w_t_contrast="كل زوج ألوان مقروء في الثيمين",
        w_t_bad="الزوج غير المقروء يُكتشف",
        w_t_guard="الشاشات تستخدم الرموز، لا القيم الخام",
        w_t_guard_bad="الشاشة ذات القيم الخام تُكتشف",
        w_t_lerp="تبديل الثيم يحرّك ألوان العلامة أيضاً",
        w_t_brands="علامتان، والمكونات نفسها، وكلتاهما مقروءة",
        w_bakery="مخبز بِت", w_cafe="مقهى بِت",
    ),
}

FILES = {
    "lib/design/tokens.dart": """// {w_c_space}
abstract final class Space {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 16.0;
  static const l = 24.0;
  static const xl = 32.0;
}

// {w_c_radius}
abstract final class Radii {
  static const s = 8.0;
  static const m = 16.0;
  static const l = 28.0;
}
""",
    "lib/design/brand.dart": """import 'package:material_ui/material_ui.dart';

// {w_c_brand}
@immutable
class Brand extends ThemeExtension<Brand> {
  const Brand({
    required this.accent,
    required this.onAccent,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.muted,
  });

  // {w_c_pairs}
  final Color accent;
  final Color onAccent;
  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color muted;

  static const light = Brand(
    accent: Color(0xFF6D4C41),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF1B5E20),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFFFFB300),
    onWarning: Color(0xFF3E2723),
    muted: Color(0xFFF3EDE7),
  );

  static const dark = Brand(
    accent: Color(0xFFD7B8A8),
    onAccent: Color(0xFF3E2723),
    success: Color(0xFF81C784),
    onSuccess: Color(0xFF0B3D0E),
    warning: Color(0xFFFFCA28),
    onWarning: Color(0xFF3E2723),
    muted: Color(0xFF2B2420),
  );

  @override
  Brand copyWith({Color? accent, Color? onAccent}) => Brand(
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    success: success,
    onSuccess: onSuccess,
    warning: warning,
    onWarning: onWarning,
    muted: muted,
  );

  // {w_c_lerp}
  @override
  Brand lerp(Brand? other, double t) {
    if (other == null) {
      return this;
    }
    return Brand(
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
    );
  }
}
""",
    "lib/design/theme.dart": """import 'package:material_ui/material_ui.dart';

import 'brand.dart';
import 'tokens.dart';

ThemeData buildTheme(Brightness brightness, {Brand? brand, Color seed = const Color(0xFF6D4C41)}) {
  // {w_c_seed}
  final colors = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.m));
  return ThemeData(
    colorScheme: colors,
    extensions: [brand ?? (brightness == Brightness.light ? Brand.light : Brand.dark)],
    // {w_c_shapes}
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: shape,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: Space.l),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(shape: shape, minimumSize: const Size(0, 48)),
    ),
    cardTheme: CardThemeData(shape: shape, margin: EdgeInsets.zero),
  );
}
""",
    "lib/design/context.dart": """import 'package:material_ui/material_ui.dart';

import 'brand.dart';

// {w_c_context}
extension DesignContext on BuildContext {
  Brand get brand => Theme.of(this).extension<Brand>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}
""",
    "lib/design/components.dart": """import 'package:material_ui/material_ui.dart';

import 'context.dart';
import 'tokens.dart';

enum ButtonKind { primary, secondary }

// {w_c_button}
class AppButton extends StatelessWidget {
  const AppButton({super.key, required this.label, required this.onPressed, this.kind = ButtonKind.primary, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final ButtonKind kind;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: Space.s,
      children: [if (icon != null) Icon(icon, size: 18), Text(label)],
    );
    return switch (kind) {
      ButtonKind.primary => FilledButton(onPressed: onPressed, child: child),
      ButtonKind.secondary => OutlinedButton(onPressed: onPressed, child: child),
    };
  }
}

enum TagKind { success, warning, neutral }

// {w_c_tag}
class StatusTag extends StatelessWidget {
  const StatusTag({super.key, required this.label, this.kind = TagKind.neutral});

  final String label;
  final TagKind kind;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final (background, foreground) = switch (kind) {
      TagKind.success => (brand.success, brand.onSuccess),
      TagKind.warning => (brand.warning, brand.onWarning),
      TagKind.neutral => (brand.muted, context.colors.onSurface),
    };
    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(Radii.s)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.s, vertical: Space.xs),
        child: Text(label, style: context.text.labelMedium!.copyWith(color: foreground)),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(Space.m), child: child),
  );
}

// {w_c_gap}
class Gap extends StatelessWidget {
  const Gap(this.size, {super.key});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size);
}
""",
    "lib/screens/menu_screen.dart": """import 'package:material_ui/material_ui.dart';

import '../design/components.dart';
import '../design/context.dart';
import '../design/tokens.dart';

// {w_c_screen}
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key, this.actions = const []});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('{w_latte}', '{w_latte_d}', 45, const StatusTag(label: '{w_new}', kind: TagKind.success)),
      ('{w_tea}', '{w_tea_d}', 25, null),
      ('{w_cake}', '{w_cake_d}', 60, const StatusTag(label: '{w_soon}', kind: TagKind.warning)),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('{w_menu}'), actions: actions),
      body: ListView.separated(
        padding: const EdgeInsets.all(Space.m),
        itemCount: items.length,
        separatorBuilder: (context, i) => const Gap(Space.m),
        itemBuilder: (context, i) {
          final (name, description, price, tag) = items[i];
          return MenuCard(name: name, description: description, price: price, tag: tag);
        },
      ),
    );
  }
}

// {w_c_card}
class MenuCard extends StatelessWidget {
  const MenuCard({super.key, required this.name, required this.description, required this.price, this.tag});

  final String name;
  final String description;
  final int price;
  final Widget? tag;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(name, style: context.text.titleLarge)),
              ?tag,
            ],
          ),
          const Gap(Space.xs),
          Text(description, style: context.text.bodyMedium!.copyWith(color: context.colors.onSurfaceVariant)),
          const Gap(Space.m),
          Row(
            children: [
              Expanded(child: Text('$price {w_egp}', style: context.text.titleMedium!.copyWith(color: context.brand.accent))),
              AppButton(label: '{w_primary}', icon: Icons.add, onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }
}
""",
    "lib/screens/catalog_screen.dart": """import 'package:material_ui/material_ui.dart';

import '../design/components.dart';
import '../design/context.dart';
import '../design/tokens.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key, this.actions = const []});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    Widget title(String text) => Padding(
      padding: const EdgeInsets.only(top: Space.l, bottom: Space.s),
      child: Text(text, style: context.text.titleMedium),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('{w_catalog}'), actions: actions),
      body: ListView(
        padding: const EdgeInsets.all(Space.m),
        children: [
          title('{w_buttons}'),
          Wrap(
            spacing: Space.s,
            runSpacing: Space.s,
            children: [
              AppButton(label: '{w_primary}', icon: Icons.add, onPressed: () {}),
              AppButton(label: '{w_secondary}', kind: ButtonKind.secondary, onPressed: () {}),
              const AppButton(label: '{w_primary}', onPressed: null),
            ],
          ),
          title('{w_tags}'),
          const Wrap(
            spacing: Space.s,
            children: [
              StatusTag(label: '{w_ready}', kind: TagKind.success),
              StatusTag(label: '{w_soon}', kind: TagKind.warning),
              StatusTag(label: '{w_new}'),
            ],
          ),
          title('{w_cards}'),
          AppCard(child: Text('{w_latte_d}', style: context.text.bodyLarge)),
          title('Space'),
          for (final (name, size) in [('xs', Space.xs), ('s', Space.s), ('m', Space.m), ('l', Space.l), ('xl', Space.xl)])
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xs),
              child: Row(
                children: [
                  SizedBox(width: Space.xl, child: Text(name, style: context.text.labelMedium)),
                  Container(width: size * 4, height: Space.s, color: context.brand.accent),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
""",
    "lib/design_app.dart": """import 'package:material_ui/material_ui.dart';

import 'design/theme.dart';
import 'screens/catalog_screen.dart';
import 'screens/menu_screen.dart';

void main() => runApp(const DesignApp());

class DesignApp extends StatefulWidget {
  const DesignApp({super.key});

  @override
  State<DesignApp> createState() => _DesignAppState();
}

class _DesignAppState extends State<DesignApp> {
  var dark = false;
  var page = 0;

  @override
  Widget build(BuildContext context) {
    final actions = [
      Semantics(
        label: '{w_dark}',
        child: Switch(value: dark, onChanged: (v) => setState(() => dark = v)),
      ),
    ];
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      {w_rtl}
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        body: [MenuScreen(actions: actions), CatalogScreen(actions: actions)][page],
        bottomNavigationBar: NavigationBar(
          selectedIndex: page,
          onDestinationSelected: (i) => setState(() => page = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.local_cafe), label: '{w_menu}'),
            NavigationDestination(icon: Icon(Icons.widgets), label: '{w_catalog}'),
          ],
        ),
      ),
    );
  }
}
""",
    "test/contrast_test.dart": """import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/design/brand.dart';
import 'package:bit_app/design/theme.dart';

/// WCAG contrast ratio: from 1 (the same colour) to 21 (black on white).
double contrast(Color a, Color b) {
  final (hi, lo) = (max(a.computeLuminance(), b.computeLuminance()), min(a.computeLuminance(), b.computeLuminance()));
  return (hi + 0.05) / (lo + 0.05);
}

Map<String, double> pairs(Brightness brightness) {
  final theme = buildTheme(brightness);
  final brand = theme.extension<Brand>()!;
  final c = theme.colorScheme;
  return {
    'text on surface': contrast(c.onSurface, c.surface),
    'text on primary': contrast(c.onPrimary, c.primary),
    'text on accent': contrast(brand.onAccent, brand.accent),
    'text on success': contrast(brand.onSuccess, brand.success),
    'text on warning': contrast(brand.onWarning, brand.warning),
    'text on muted': contrast(c.onSurface, brand.muted),
    'price (accent on surface)': contrast(brand.accent, c.surface),
  };
}

void main() {
  test('{w_t_contrast}', () {
    for (final b in Brightness.values) {
      debugPrint(b.name);
      pairs(b).forEach((name, ratio) {
        debugPrint('  ${name.padRight(28)}${ratio.toStringAsFixed(1)} : 1');
        expect(ratio, greaterThanOrEqualTo(4.5), reason: '$name in ${b.name}');
      });
    }
  });
}
""",
    "test/contrast_bad_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'contrast_test.dart';

void main() {
  test('{w_t_bad}', () {
    // {w_c_amber}
    final ratio = contrast(const Color(0xFFFFFFFF), const Color(0xFFFFB300));
    expect(ratio, greaterThanOrEqualTo(4.5), reason: 'white on amber is ${ratio.toStringAsFixed(1)} : 1');
  });
}
""",
    "test/guard_test.dart": """import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// {w_c_raw}
final rules = {
  'a raw colour': RegExp(r'Color\\(0x|Colors\\.(?!transparent)'),
  'a raw spacing': RegExp(r'EdgeInsets\\.\\w+\\([^)]*\\b\\d'),
  'a raw font size': RegExp(r'fontSize:'),
};

List<String> violations(String folder) => [
  for (final file in Directory(folder).listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')))
    for (final (i, line) in file.readAsLinesSync().indexed)
      for (final MapEntry(key: what, value: pattern) in rules.entries)
        if (pattern.hasMatch(line)) '${file.path}:${i + 1}: $what',
];

void main() {
  test('{w_t_guard}', () {
    expect(violations('lib/screens'), isEmpty);
  });
}
""",
    "test/guard_bad_test.dart": """import 'package:flutter_test/flutter_test.dart';

import 'guard_test.dart';

void main() {
  test('{w_t_guard_bad}', () {
    expect(violations('test/fixtures'), isEmpty);
  });
}
""",
    "test/fixtures/hurried_screen.dart": """import 'package:material_ui/material_ui.dart';

class HurriedScreen extends StatelessWidget {
  const HurriedScreen({super.key});

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFF3EDE7),
    padding: const EdgeInsets.all(12),
    child: const Text('Sale!', style: TextStyle(fontSize: 22, color: Colors.red)),
  );
}
""",
    "test/lerp_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/design/brand.dart';

String hex(Color c) => '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

void main() {
  test('{w_t_lerp}', () {
    for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
      final b = Brand.light.lerp(Brand.dark, t);
      debugPrint('t = $t   accent ${hex(b.accent)}   muted ${hex(b.muted)}');
    }
    expect(Brand.light.lerp(Brand.dark, 1).accent, Brand.dark.accent);
  });
}
""",
    # Project (challenge)
    "lib/design/brands.dart": """import 'package:material_ui/material_ui.dart';

import 'brand.dart';

// {w_c_second}
const bakeryLight = Brand(
  accent: Color(0xFFAD1457),
  onAccent: Color(0xFFFFFFFF),
  success: Color(0xFF1B5E20),
  onSuccess: Color(0xFFFFFFFF),
  warning: Color(0xFFFFB300),
  onWarning: Color(0xFF3E2723),
  muted: Color(0xFFFCE4EC),
);
const bakerySeed = Color(0xFFAD1457);
""",
    "lib/brands_app.dart": """import 'package:material_ui/material_ui.dart';

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
      {w_rtl}
      theme: bakery ? buildTheme(Brightness.light, brand: bakeryLight, seed: bakerySeed) : buildTheme(Brightness.light),
      home: MenuScreen(
        actions: [
          TextButton(onPressed: () => setState(() => bakery = !bakery), child: Text(bakery ? '{w_bakery}' : '{w_cafe}')),
        ],
      ),
    );
  }
}
""",
    "test/brands_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/design/brand.dart';
import 'package:bit_app/design/brands.dart';
import 'package:bit_app/design/theme.dart';

import 'contrast_test.dart';

void main() {
  test('{w_t_brands}', () {
    final theme = buildTheme(Brightness.light, brand: bakeryLight, seed: bakerySeed);
    final brand = theme.extension<Brand>()!;
    final c = theme.colorScheme;
    for (final (name, ratio) in [
      ('text on accent', contrast(brand.onAccent, brand.accent)),
      ('price on surface', contrast(brand.accent, c.surface)),
      ('text on muted', contrast(c.onSurface, brand.muted)),
      ('text on primary', contrast(c.onPrimary, c.primary)),
    ]) {
      debugPrint('bakery  ${name.padRight(18)}${ratio.toStringAsFixed(1)} : 1');
      expect(ratio, greaterThanOrEqualTo(4.5));
    }
  });
}
""",
}


def failure(lines):
    """The failing run, without the stack trace."""
    end = next(i for i, l in enumerate(lines) if l.strip().startswith("package:matcher"))
    return [l for l in lines[:end] if l.strip()]


SHOTS = [
    ("menu-light.png", "lib/design_app.dart", ""),
    ("menu-dark.png", "lib/design_app.dart", "switch={w_dark}|wait=800"),
    ("catalog-light.png", "lib/design_app.dart", "at={w_x2},745|wait=800"),
    ("catalog-dark.png", "lib/design_app.dart", "at={w_x2},745|wait=500|switch={w_dark}|wait=800"),
    ("bakery.png", "lib/brands_app.dart", ""),
]
T["en"].update(w_x2="292", w_c_card="Each card is its own widget, so it reads the theme from its own context, and rebuilds when the theme changes.",
               w_c_amber="White text on the warning amber: the first idea for the \"almost sold out\" tag.",
               w_c_raw="Raw values that belong in lib/design, never in a screen.",
               w_c_second="A second brand from the same components: only the tokens change.")
T["ar"].update(w_x2="98", w_c_card="كل بطاقة Widget خاص بها، فتقرأ الثيم من الـ context الخاص بها، وتُبنى من جديد حين يتغير الثيم.",
               w_c_amber="نص أبيض على كهرماني التحذير: أول فكرة لوسم «أوشك أن ينفد».",
               w_c_raw="قيم خام مكانها lib/design، لا الشاشات أبداً.",
               w_c_second="علامة ثانية من المكونات نفسها: لا تتغير إلا الرموز.")

TESTS = [
    ("contrast-test.sh", "test/contrast_test.dart"),
    ("contrast-bad.sh", "test/contrast_bad_test.dart", failure),
    ("guard-test.sh", "test/guard_test.dart"),
    ("guard-bad.sh", "test/guard_bad_test.dart", failure),
    ("lerp-test.sh", "test/lerp_test.dart"),
    ("projects/brands-test.sh", "test/brands_test.dart"),
]


def main():
    flutter_gallery(HERE, T, FILES, SHOTS, TESTS)


if __name__ == "__main__":
    main()
