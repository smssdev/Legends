"""Writes the examples of Book 6, chapter "Accessibility", in English and Arabic: a menu written in a hurry
and the same menu written with care, checked four ways: what the browser hands a screen reader (its
accessibility tree, read by Playwright), Flutter's accessibility guidelines as tests, text at twice the size,
and announcements, focus order and a custom control in the projects.
Run: python3 make.py   (needs Flutter 3.50.1, Node.js and Playwright's Chromium)
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent.parent / "b5"))
from kit import flutter_gallery  # noqa: E402

T = {
    "en": dict(
        w_locale="",
        w_menu="Menu", w_latte="Latte", w_tea="Mint tea", w_cake="Cherry cake", w_egp="EGP",
        w_latte_d="Espresso and steamed milk", w_tea_d="Fresh mint, lightly sweet", w_cake_d="Baked this morning",
        w_total="Total", w_checkout="Check out", w_add="Add", w_fav="Save", w_added="added", w_items="items in your order",
        w_name="Your name", w_phone="Phone", w_pay="Pay", w_order="Your order",
        w_size="Cup size", w_small="Small", w_medium="Medium", w_large="Large",
        w_c_photo="The photo is decoration: the name already says what it is.",
        w_c_merge="One stop for the screen reader: name, description and price, read together.",
        w_c_tooltip="Every icon button says what it does, and to which drink.",
        w_c_wrap="Big text wraps to a second line instead of running off the screen.",
        w_c_price="Under the name, not beside it: at large sizes a row has no width to spare.",
        w_c_scale="Text at the size the person chose; the screenshots use 2 to show large text.",
        w_c_announce="Tell screen reader users what changed, since they cannot see the badge.",
        w_c_order="Pay is drawn at the top, but it should be reached last, after the fields.",
        w_c_control="A custom control must say what it is, and which choice is selected.",
        w_t_guidelines="four accessibility guidelines, hurried and careful menus",
        w_t_large="the menus with text at twice the size",
        w_t_announce="adding a drink is announced",
        w_t_order="the order of the Tab key",
        w_t_control="the cup sizes are buttons in a group, one selected",
        w_t_alone="the grey description, checked on its own",
        w_t_reading="the reading order of a right-to-left menu",
    ),
    "ar": dict(
        w_locale="  // العربية لغة التطبيق: فيصير التخطيط وترتيب القراءة كلاهما من اليمين (القسم 11.4).\n"
                 "  locale: const Locale('ar'),\n  supportedLocales: const [Locale('ar')],\n"
                 "  localizationsDelegates: GlobalMaterialLocalizations.delegates,\n",
        w_menu="القائمة", w_latte="لاتيه", w_tea="شاي بالنعناع", w_cake="كيك الكرز", w_egp="جنيه",
        w_latte_d="إسبريسو وحليب مبخّر", w_tea_d="نعناع طازج، محلّى قليلاً", w_cake_d="مخبوز هذا الصباح",
        w_total="المجموع", w_checkout="إتمام الطلب", w_add="أضف", w_fav="احفظ", w_added="أُضيف", w_items="قطع في طلبك",
        w_name="اسمك", w_phone="الهاتف", w_pay="ادفع", w_order="طلبك",
        w_size="حجم الكوب", w_small="صغير", w_medium="وسط", w_large="كبير",
        w_c_photo="الصورة زينة: الاسم يقول ما هي.",
        w_c_merge="وقفة واحدة لقارئ الشاشة: الاسم والوصف والسعر تُقرأ معاً.",
        w_c_tooltip="كل زر أيقونة يقول ما يفعل، ولأي مشروب.",
        w_c_wrap="النص الكبير ينتقل إلى سطر ثانٍ بدل أن يخرج من الشاشة.",
        w_c_price="تحت الاسم لا بجانبه: في الأحجام الكبيرة لا يبقى في الصف عرض زائد.",
        w_c_scale="النص بالحجم الذي اختاره الشخص؛ واللقطات تستخدم 2 لتُظهر النص الكبير.",
        w_c_announce="أخبر مستخدمي قارئ الشاشة بما تغيّر، فهم لا يرون الشارة.",
        w_c_order="«ادفع» مرسوم في الأعلى، لكن يجب أن يُبلغ أخيراً، بعد الحقول.",
        w_c_control="المكوّن المصنوع يدوياً يجب أن يقول ما هو، وأي خيار مختار.",
        w_t_guidelines="أربعة إرشادات للإتاحة، القائمتان المستعجلة والمتأنية",
        w_t_large="القائمتان والنص بضعف حجمه",
        w_t_announce="إضافة مشروب تُعلَن",
        w_t_order="ترتيب مفتاح Tab",
        w_t_control="أحجام الكوب أزرار في مجموعة، واحد منها مختار",
        w_t_alone="الوصف الرمادي، مفحوصاً وحده",
        w_t_reading="ترتيب القراءة في قائمة من اليمين إلى اليسار",
    ),
}

FILES = {
    "lib/cafe.dart": """import 'package:material_ui/material_ui.dart';

const drinks = [
  ('{w_latte}', '{w_latte_d}', 45),
  ('{w_tea}', '{w_tea_d}', 30),
  ('{w_cake}', '{w_cake_d}', 55),
];

// {w_c_scale}
Widget cafe(Widget home, {double textScale = 1}) => MaterialApp(
  debugShowCheckedModeBanner: false,
{w_locale}  theme: ThemeData(colorSchemeSeed: Colors.brown),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: home,
);
""",
    "lib/menu_hurried.dart": """import 'package:material_ui/material_ui.dart';

import 'cafe.dart';

void main() => runApp(cafe(const HurriedMenu()));

class HurriedMenu extends StatelessWidget {
  const HurriedMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('{w_menu}')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                for (final (name, about, price) in drinks)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      spacing: 12,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(color: Colors.brown, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.local_cafe, color: Colors.white),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: Theme.of(context).textTheme.titleMedium),
                              Text(about, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text('$price {w_egp}'),
                        GestureDetector(onTap: () {}, child: const Icon(Icons.favorite_border, size: 20)),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
                            child: Icon(Icons.add, size: 16, color: colors.onPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            height: 64,
            color: colors.primaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('{w_total}: 90 {w_egp}', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                FilledButton(onPressed: () {}, child: const Text('{w_checkout}')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
""",
    "lib/menu_hurried_large.dart": """import 'package:material_ui/material_ui.dart';

import 'cafe.dart';
import 'menu_hurried.dart';

void main() => runApp(cafe(const HurriedMenu(), textScale: 2));
""",
    "lib/menu_careful.dart": """import 'package:material_ui/material_ui.dart';

import 'cafe.dart';

void main() => runApp(cafe(const CarefulMenu()));

class CarefulMenu extends StatelessWidget {
  const CarefulMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('{w_menu}')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                for (final (name, about, price) in drinks)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          // {w_c_merge}
                          child: MergeSemantics(
                            child: Row(
                              spacing: 12,
                              children: [
                                // {w_c_photo}
                                ExcludeSemantics(
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(color: Colors.brown, borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.local_cafe, color: Colors.white),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: text.titleMedium),
                                      Text(about, style: text.bodySmall!.copyWith(color: colors.onSurfaceVariant)),
                                      // {w_c_price}
                                      Text('$price {w_egp}', style: text.labelLarge),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // {w_c_tooltip}
                        IconButton(tooltip: '{w_fav} $name', onPressed: () {}, icon: const Icon(Icons.favorite_border)),
                        IconButton.filled(tooltip: '{w_add} $name', onPressed: () {}, icon: const Icon(Icons.add)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            color: colors.primaryContainer,
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            // {w_c_wrap}
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              children: [
                Text('{w_total}: 90 {w_egp}', style: text.titleLarge),
                FilledButton(onPressed: () {}, child: const Text('{w_checkout}')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
""",
    "lib/menu_careful_large.dart": """import 'package:material_ui/material_ui.dart';

import 'cafe.dart';
import 'menu_careful.dart';

void main() => runApp(cafe(const CarefulMenu(), textScale: 2));
""",
    "test/guidelines_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe.dart';
import 'package:bit_app/menu_careful.dart';
import 'package:bit_app/menu_hurried.dart';

const guidelines = {
  'labeled tap targets': labeledTapTargetGuideline,
  'Android tap targets (48 x 48)': androidTapTargetGuideline,
  'iOS tap targets (44 x 44)': iOSTapTargetGuideline,
  'text contrast': textContrastGuideline,
};

Future<int> check(WidgetTester tester, String name, Widget menu) async {
  final semantics = tester.ensureSemantics();
  await tester.pumpWidget(cafe(menu));
  var failed = 0;
  debugPrint('$name menu:');
  for (final MapEntry(key: rule, value: guideline) in guidelines.entries) {
    final result = await guideline.evaluate(tester);
    if (!result.passed) {
      failed++;
    }
    final first = result.reason?.split('\\n').first ?? '';
    debugPrint('  ${result.passed ? 'pass' : 'FAIL'}  ${rule.padRight(30)}${first.length > 70 ? '${first.substring(0, 70)}...' : first}');
  }
  semantics.dispose();
  return failed;
}

void main() {
  testWidgets('{w_t_guidelines}', (tester) async {
    final hurried = await check(tester, 'hurried', const HurriedMenu());
    final careful = await check(tester, 'careful', const CarefulMenu());
    expect(hurried, greaterThan(0));
    expect(careful, 0);
  });
}
""",
    "test/large_text_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe.dart';
import 'package:bit_app/menu_careful.dart';
import 'package:bit_app/menu_hurried.dart';

Future<void> atTwice(WidgetTester tester, String name, Widget menu) async {
  tester.view.physicalSize = const Size(1170, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(cafe(menu, textScale: 2));
  final problem = tester.takeException();
  debugPrint('$name menu at 200%: ${problem == null ? 'fits' : problem.toString().split('\\n').first}');
}

void main() {
  testWidgets('{w_t_large}', (tester) async {
    await atTwice(tester, 'hurried', const HurriedMenu());
    await atTwice(tester, 'careful', const CarefulMenu());
  });
}
""",
    "test/contrast_alone_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe.dart';

void main() {
  testWidgets('{w_t_alone}', (tester) async {
    final semantics = tester.ensureSemantics();
    final grey = Text('{w_latte_d}', style: TextStyle(color: Colors.grey.shade400, fontSize: 12));
    await tester.pumpWidget(cafe(Scaffold(body: Center(child: grey))));
    final result = await textContrastGuideline.evaluate(tester);
    debugPrint('text contrast: ${result.passed ? 'pass' : 'FAIL'}');
    debugPrint(result.reason!.split('\\n').where((line) => line.contains('ratio')).join('\\n'));
    expect(result.passed, isFalse);
    semantics.dispose();
  });
}
""",
    "test/reading_order_test.dart": """import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/menu_careful.dart';

// What a screen reader visits, in order, as it moves forward through the screen.
List<String> heard(WidgetTester tester) {
  final said = <String>[];
  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    final name = data.label.isNotEmpty ? data.label : data.tooltip;
    if (name.isNotEmpty) {
      said.add(name.split('\\n').first);
    }
    node.debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder).forEach(visit);
  }

  visit(tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!);
  return said;
}

Future<void> firstRow(WidgetTester tester, String how, Widget app) async {
  await tester.pumpWidget(app);
  debugPrint('${how.padRight(22)}${heard(tester).skip(1).take(3).join('  ->  ')}');
}

void main() {
  testWidgets('{w_t_reading}', (tester) async {
    final semantics = tester.ensureSemantics();
    await firstRow(
      tester,
      'Directionality only:',
      MaterialApp(
        key: const ValueKey(1),
        builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
        home: const CarefulMenu(),
      ),
    );
    await firstRow(
      tester,
      'Arabic locale:',
      const MaterialApp(
        key: ValueKey(2),
        locale: Locale('ar'),
        supportedLocales: [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: CarefulMenu(),
      ),
    );
    semantics.dispose();
  });
}
""",
    # Projects
    "lib/announce.dart": """import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';

import 'cafe.dart';

void main() => runApp(cafe(const OrderCounter()));

class OrderCounter extends StatefulWidget {
  const OrderCounter({super.key});

  @override
  State<OrderCounter> createState() => _OrderCounterState();
}

class _OrderCounterState extends State<OrderCounter> {
  var count = 0;

  void add() {
    setState(() => count++);
    // {w_c_announce}
    SemanticsService.sendAnnouncement(View.of(context), '{w_latte} {w_added}, $count {w_items}', Directionality.of(context));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('{w_order}'),
        actions: [Badge.count(count: count, child: const Icon(Icons.local_cafe)), const SizedBox(width: 16)],
      ),
      body: Center(child: FilledButton(onPressed: add, child: const Text('{w_add} {w_latte}'))),
    );
  }
}
""",
    "test/announce_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/announce.dart';
import 'package:bit_app/cafe.dart';

void main() {
  testWidgets('{w_t_announce}', (tester) async {
    await tester.pumpWidget(cafe(const OrderCounter()));
    await tester.tap(find.text('{w_add} {w_latte}'));
    await tester.tap(find.text('{w_add} {w_latte}'));
    await tester.pump();
    final said = tester.takeAnnouncements();
    for (final announcement in said) {
      debugPrint('announced (${announcement.assertiveness.name}): "${announcement.message}"');
    }
    expect(said, hasLength(2));
  });
}
""",
    "lib/checkout.dart": """import 'package:material_ui/material_ui.dart';

import 'cafe.dart';

void main() => runApp(cafe(const Checkout(ordered: true)));

class Checkout extends StatelessWidget {
  const Checkout({super.key, required this.ordered});

  final bool ordered;

  @override
  Widget build(BuildContext context) {
    final pay = FilledButton(focusNode: FocusNode(debugLabel: 'pay'), onPressed: () {}, child: const Text('{w_pay}'));
    final page = Scaffold(
      appBar: AppBar(
        title: const Text('{w_checkout}'),
        // {w_c_order}
        actions: [ordered ? FocusTraversalOrder(order: const NumericFocusOrder(3), child: pay) : pay],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 16,
          children: [
            FocusTraversalOrder(
              order: const NumericFocusOrder(1),
              child: TextField(focusNode: FocusNode(debugLabel: 'name'), decoration: const InputDecoration(labelText: '{w_name}')),
            ),
            FocusTraversalOrder(
              order: const NumericFocusOrder(2),
              child: TextField(focusNode: FocusNode(debugLabel: 'phone'), decoration: const InputDecoration(labelText: '{w_phone}')),
            ),
          ],
        ),
      ),
    );
    return ordered ? FocusTraversalGroup(policy: OrderedTraversalPolicy(), child: page) : page;
  }
}
""",
    "test/focus_order_test.dart": """import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe.dart';
import 'package:bit_app/checkout.dart';

Future<List<String>> tabs(WidgetTester tester, {required bool ordered}) async {
  await tester.pumpWidget(cafe(Checkout(key: ValueKey(ordered), ordered: ordered)));
  final visited = <String>[];
  for (var i = 0; i < 3; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    visited.add(FocusManager.instance.primaryFocus?.debugLabel ?? '?');
  }
  return visited;
}

void main() {
  testWidgets('{w_t_order}', (tester) async {
    debugPrint('by position: ${(await tabs(tester, ordered: false)).join(' -> ')}');
    final ordered = await tabs(tester, ordered: true);
    debugPrint('in order:    ${ordered.join(' -> ')}');
    expect(ordered, ['name', 'phone', 'pay']);
  });
}
""",
    "lib/cup_size.dart": """import 'package:material_ui/material_ui.dart';

import 'cafe.dart';

void main() => runApp(cafe(const Scaffold(body: Center(child: CupSize()))));

class CupSize extends StatefulWidget {
  const CupSize({super.key});

  @override
  State<CupSize> createState() => _CupSizeState();
}

class _CupSizeState extends State<CupSize> {
  var chosen = 1;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const sizes = ['{w_small}', '{w_medium}', '{w_large}'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        for (final (i, size) in sizes.indexed)
          // {w_c_control}
          Semantics(
            button: true,
            selected: i == chosen,
            inMutuallyExclusiveGroup: true,
            label: '{w_size}: $size',
            excludeSemantics: true,
            onTap: () => setState(() => chosen = i),
            child: GestureDetector(
              onTap: () => setState(() => chosen = i),
              child: Container(
                constraints: const BoxConstraints(minWidth: 72, minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: i == chosen ? colors.primary : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(size, style: TextStyle(color: i == chosen ? colors.onPrimary : colors.onSurface)),
              ),
            ),
          ),
      ],
    );
  }
}
""",
    "test/cup_size_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe.dart';
import 'package:bit_app/cup_size.dart';

void main() {
  testWidgets('{w_t_control}', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(cafe(const Scaffold(body: Center(child: CupSize()))));
    final medium = find.bySemanticsLabel('{w_size}: {w_medium}');
    final large = find.bySemanticsLabel('{w_size}: {w_large}');
    expect(tester.getSemantics(medium), isSemantics(isButton: true, isSelected: true, isInMutuallyExclusiveGroup: true, hasTapAction: true));
    expect(tester.getSemantics(large), isSemantics(isButton: true, isSelected: false));
    tester.semantics.tap(find.semantics.byLabel('{w_size}: {w_large}'));
    await tester.pump();
    expect(tester.getSemantics(large), isSemantics(isSelected: true));
    expect(tester.getSemantics(medium), isSemantics(isSelected: false));
    debugPrint('a screen reader double-tap on {w_large} selected it, and {w_medium} is no longer selected');
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });
}
""",
}

SHOTS = [
    ("hurried.png", "lib/menu_hurried.dart", "aria=1"),
    ("careful.png", "lib/menu_careful.dart", "aria=1"),
    ("hurried-large.png", "lib/menu_hurried_large.dart", "wait=500"),
    ("careful-large.png", "lib/menu_careful_large.dart", "wait=500"),
    ("cup-size.png", "lib/cup_size.dart", "wait=500"),
]

TESTS = [
    ("guidelines-test.sh", "test/guidelines_test.dart"),
    ("large-text-test.sh", "test/large_text_test.dart"),
    ("contrast-alone-test.sh", "test/contrast_alone_test.dart"),
    ("reading-order-test.sh", "test/reading_order_test.dart"),
    ("projects/announce-test.sh", "test/announce_test.dart"),
    ("projects/focus-order-test.sh", "test/focus_order_test.dart"),
    ("projects/cup-size-test.sh", "test/cup_size_test.dart"),
]


def main():
    flutter_gallery(HERE, T, FILES, SHOTS, TESTS)


if __name__ == "__main__":
    main()
