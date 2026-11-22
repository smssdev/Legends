"""Writes the examples of Book 6, chapter "Animations That Feel Native", in English and Arabic: motion tokens,
implicit and explicit animations, a Hero, a staggered list, a page transition, and reduced motion. Tests print
the values of each animation over time; filmstrips are screenshots taken while the motion runs, slowed down
with timeDilation so that the browser can follow.
Run: python3 make.py   (needs Flutter 3.50.1, Node.js and Playwright's Chromium)
"""
import sys
from pathlib import Path

from PIL import Image

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent.parent / "b5"))
from kit import flutter_gallery  # noqa: E402

T = {
    "en": dict(
        w_rtl="",
        w_order="Your order", w_add="Add a latte", w_items="items", w_checkout="Check out", w_egp="EGP",
        w_empty="Nothing yet", w_menu="Menu", w_brewing="Brewing your latte", w_latte="Latte", w_tea="Mint tea",
        w_cake="Cherry cake", w_juice="Orange juice", w_latte_d="Espresso and steamed milk, in a big cup.",
        w_open="Open", w_next="Next step", w_replay="Play again",
        w_c_tokens="Motion tokens: three durations and three curves, like the spacing scale of Chapter 7.",
        w_c_enter="Things that arrive slow down at the end; things that leave speed up.",
        w_c_reduce="People who turn on reduced motion get the result at once.",
        w_c_implicit="Implicit: change the value, and the widget animates to it by itself.",
        w_c_switcher="A new key is a new child: the old number leaves while the new one arrives.",
        w_c_explicit="Explicit: a controller drives the animation, here for ever, until the page closes.",
        w_c_child="The cup is built once and passed in; only the ring is rebuilt on each frame.",
        w_c_hero="The same tag on both pages: Flutter flies the circle from one to the other.",
        w_c_slow="Slowed down for the book's filmstrips: every animation takes ten times longer.",
        w_c_stagger="Each item starts a little later: Interval gives each one its slice of the same controller.",
        w_c_transition="One transition for every page of the app, set once in the theme.",
        w_t_curves="the curves, step by step",
        w_t_implicit="AnimatedOpacity, frame by frame",
        w_t_child="the child of an AnimatedBuilder is built once",
        w_t_reduce="with reduced motion, the change is immediate",
        w_t_badge="both numbers are on screen while they cross",
        w_t_stagger="each item arrives a little after the one before",
        w_t_transition="the page transition fades and slides, unless motion is reduced",
    ),
    "ar": dict(
        w_rtl="// من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.\n"
              "builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),\n",
        w_order="طلبك", w_add="أضف لاتيه", w_items="قطع", w_checkout="إتمام الطلب", w_egp="جنيه",
        w_empty="لا شيء بعد", w_menu="القائمة", w_brewing="نحضّر اللاتيه", w_latte="لاتيه", w_tea="شاي بالنعناع",
        w_cake="كيك الكرز", w_juice="عصير برتقال", w_latte_d="إسبريسو وحليب مبخّر، في كوب كبير.",
        w_open="افتح", w_next="الخطوة التالية", w_replay="أعد الحركة",
        w_c_tokens="رموز الحركة: ثلاث مدد وثلاثة منحنيات، مثل مقياس المسافات في الفصل 7.",
        w_c_enter="ما يصل يبطئ في النهاية؛ وما يغادر يسرع.",
        w_c_reduce="من يفعّل «تقليل الحركة» يحصل على النتيجة فوراً.",
        w_c_implicit="ضمنية: غيّر القيمة، فيتحرك الـ Widget إليها وحده.",
        w_c_switcher="مفتاح جديد يعني ابناً جديداً: الرقم القديم يغادر والجديد يصل.",
        w_c_explicit="صريحة: متحكم يقود الحركة، هنا إلى الأبد، حتى تُغلق الصفحة.",
        w_c_child="الكوب يُبنى مرة ويُمرَّر؛ والحلقة وحدها يُعاد بناؤها مع كل إطار.",
        w_c_hero="الوسم نفسه في الصفحتين: فيطير Flutter بالدائرة من واحدة إلى الأخرى.",
        w_c_slow="مبطَّأة لأشرطة صور الكتاب: كل حركة تأخذ عشرة أضعاف وقتها.",
        w_c_stagger="كل عنصر يبدأ بعد قليل: وInterval تعطي كلاً منها شريحته من المتحكم نفسه.",
        w_c_transition="انتقال واحد لكل صفحات التطبيق، يُضبط مرة في الثيم.",
        w_t_curves="المنحنيات، خطوة خطوة",
        w_t_implicit="AnimatedOpacity، إطاراً إطاراً",
        w_t_child="ابن AnimatedBuilder يُبنى مرة واحدة",
        w_t_reduce="مع تقليل الحركة يكون التغيير فورياً",
        w_t_badge="الرقمان على الشاشة معاً وهما يتقاطعان",
        w_t_stagger="كل عنصر يصل بعد الذي قبله بقليل",
        w_t_transition="انتقال الصفحة يتلاشى وينزلق، ما لم تُقلَّل الحركة",
    ),
}

APP = """void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      {w_rtl}
      theme: ThemeData(colorSchemeSeed: Colors.deepOrange),
      home: const %s(),
    ),
  );
}
"""

SLOW = """import 'package:flutter/scheduler.dart';

import '%s.dart' as app;

// {w_c_slow}
void main() {
  timeDilation = 10;
  app.main();
}
"""

FILES = {
    "lib/motion/motion.dart": """import 'package:material_ui/material_ui.dart';

// {w_c_tokens}
abstract final class Motion {
  static const short = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 300);
  static const long = Duration(milliseconds: 500);

  // {w_c_enter}
  static const enter = Easing.emphasizedDecelerate;
  static const exit = Easing.emphasizedAccelerate;
  static const move = Easing.standard;
}

// {w_c_reduce}
Duration motion(BuildContext context, Duration duration) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
""",
    "lib/order_card.dart": """import 'package:material_ui/material_ui.dart';

import 'motion/motion.dart';

""" + APP % "OrderPage" + """
class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  var count = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final full = count > 0;
    return Scaffold(
      appBar: AppBar(title: const Text('{w_order}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // {w_c_implicit}
            AnimatedContainer(
              key: const ValueKey('card'),
              duration: motion(context, Motion.medium),
              curve: Motion.move,
              height: full ? 180 : 96,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: full ? colors.primaryContainer : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(full ? 28 : 12),
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('{w_order}', style: Theme.of(context).textTheme.titleLarge)),
                      // {w_c_switcher}
                      AnimatedSwitcher(
                        duration: motion(context, Motion.medium),
                        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                        child: CircleAvatar(key: ValueKey(count), child: Text('$count')),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 0,
                    child: AnimatedOpacity(
                    opacity: full ? 1 : 0,
                    duration: motion(context, Motion.medium),
                    curve: Motion.enter,
                    child: Text('${count * 45} {w_egp}', style: Theme.of(context).textTheme.headlineMedium),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: () => setState(() => count++), icon: const Icon(Icons.add), label: const Text('{w_add}')),
          ],
        ),
      ),
    );
  }
}
""",
    "lib/order_card_slow.dart": SLOW % "order_card",
    "lib/brewing.dart": """import 'dart:math';

import 'package:material_ui/material_ui.dart';

""" + APP % "BrewingPage" + """
var cupBuilds = 0;

class Cup extends StatelessWidget {
  const Cup({super.key});

  @override
  Widget build(BuildContext context) {
    cupBuilds++;
    return const Icon(Icons.local_cafe, size: 72);
  }
}

// {w_c_explicit}
class BrewingPage extends StatefulWidget {
  const BrewingPage({super.key});

  @override
  State<BrewingPage> createState() => _BrewingPageState();
}

class _BrewingPageState extends State<BrewingPage> with SingleTickerProviderStateMixin {
  late final turns = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

  @override
  void dispose() {
    turns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('{w_brewing}')),
      body: Center(
        child: AnimatedBuilder(
          animation: turns,
          // {w_c_child}
          child: const Cup(),
          builder: (context, child) => CustomPaint(
            painter: Ring(turns.value, color),
            child: SizedBox.square(dimension: 180, child: Center(child: child)),
          ),
        ),
      ),
    );
  }
}

class Ring extends CustomPainter {
  Ring(this.value, this.color);

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Offset.zero & size, value * 2 * pi, pi * 1.2, false, paint);
  }

  @override
  bool shouldRepaint(Ring old) => old.value != value;
}
""",
    "lib/hero_menu.dart": """import 'package:material_ui/material_ui.dart';

""" + APP % "MenuPage" + """
const drinks = [('latte', '{w_latte}', Colors.brown), ('tea', '{w_tea}', Colors.green), ('juice', '{w_juice}', Colors.orange)];

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{w_menu}')),
      body: ListView(
        children: [
          for (final (id, name, color) in drinks)
            ListTile(
              // {w_c_hero}
              leading: Hero(tag: id, child: CircleAvatar(backgroundColor: color, child: const Icon(Icons.local_cafe, color: Colors.white))),
              title: Text(name),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DrinkPage(id: id, name: name, color: color))),
            ),
        ],
      ),
    );
  }
}

class DrinkPage extends StatelessWidget {
  const DrinkPage({super.key, required this.id, required this.name, required this.color});

  final String id;
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 24,
          children: [
            Hero(
              tag: id,
              child: CircleAvatar(radius: 100, backgroundColor: color, child: const Icon(Icons.local_cafe, color: Colors.white, size: 96)),
            ),
            Text('{w_latte_d}', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
""",
    "lib/hero_menu_slow.dart": SLOW % "hero_menu",
    "test/curves_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('{w_t_curves}', () {
    final curves = {
      'linear': Curves.linear,
      'easeInOut': Curves.easeInOut,
      'standard': Easing.standard,
      'emphasizedDecelerate': Easing.emphasizedDecelerate,
    };
    debugPrint('${'time'.padRight(22)}${[for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) t.toStringAsFixed(2).padLeft(6)].join()}');
    curves.forEach((name, curve) {
      final row = [for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) curve.transform(t).toStringAsFixed(2).padLeft(6)];
      debugPrint('${name.padRight(22)}${row.join()}');
    });
  });
}
""",
    "test/implicit_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/order_card.dart';

void main() {
  testWidgets('{w_t_implicit}', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OrderPage()));
    final total = find.ancestor(of: find.textContaining('{w_egp}'), matching: find.byType(FadeTransition)).first;
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    for (var ms = 0; ms <= 300; ms += 50) {
      final opacity = tester.widget<FadeTransition>(total).opacity.value;
      final height = tester.getSize(find.byKey(const ValueKey('card'))).height;
      debugPrint('${'$ms ms'.padRight(8)}opacity ${opacity.toStringAsFixed(2)}   height ${height.toStringAsFixed(0)}');
      await tester.pump(const Duration(milliseconds: 50));
    }
  });
}
""",
    "test/child_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/brewing.dart';

void main() {
  testWidgets('{w_t_child}', (tester) async {
    cupBuilds = 0;
    await tester.pumpWidget(const MaterialApp(home: BrewingPage()));
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    debugPrint('60 frames of the ring, the cup was built $cupBuilds time');
    expect(cupBuilds, 1);
  });
}
""",
    "test/reduce_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/order_card.dart';

void main() {
  testWidgets('{w_t_reduce}', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(data: MediaQueryData(disableAnimations: true), child: MaterialApp(home: OrderPage())),
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pump();
    final height = tester.getSize(find.byKey(const ValueKey('card'))).height;
    debugPrint('one frame after the tap: height ${height.toStringAsFixed(0)}');
    expect(height, 180);
  });
}
""",
    # Projects
    "test/badge_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/order_card.dart';

void main() {
  testWidgets('{w_t_badge}', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OrderPage()));
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    debugPrint('halfway: "0" ${find.text('0').evaluate().length}, "1" ${find.text('1').evaluate().length}');
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('0'), findsNothing);
  });
}
""",
    "lib/stagger.dart": """import 'package:material_ui/material_ui.dart';

import 'motion/motion.dart';

""" + APP % "StaggerPage" + """
const items = ['{w_latte}', '{w_tea}', '{w_cake}', '{w_juice}'];

class StaggerPage extends StatefulWidget {
  const StaggerPage({super.key});

  @override
  State<StaggerPage> createState() => _StaggerPageState();
}

class _StaggerPageState extends State<StaggerPage> with SingleTickerProviderStateMixin {
  late final controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller.duration = motion(context, const Duration(milliseconds: 800));
    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('{w_menu}'),
        actions: [IconButton(tooltip: '{w_replay}', icon: const Icon(Icons.replay), onPressed: () => controller.forward(from: 0))],
      ),
      body: ListView(
        children: [
          for (final (i, name) in items.indexed)
            Builder(
              builder: (context) {
                // {w_c_stagger}
                final slice = CurvedAnimation(parent: controller, curve: Interval(i * 0.15, 0.4 + i * 0.15, curve: Motion.enter));
                return FadeTransition(
                  opacity: slice,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.6), end: Offset.zero).animate(slice),
                    child: Card(margin: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: ListTile(title: Text(name))),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
""",
    "lib/stagger_slow.dart": SLOW % "stagger",
    "test/stagger_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/stagger.dart';

void main() {
  testWidgets('{w_t_stagger}', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StaggerPage()));
    for (var ms = 0; ms <= 800; ms += 200) {
      final row = [
        for (final name in items)
          tester.widget<FadeTransition>(find.ancestor(of: find.text(name), matching: find.byType(FadeTransition)).first).opacity.value,
      ];
      debugPrint('${'$ms ms'.padRight(8)}${row.map((o) => o.toStringAsFixed(2).padLeft(6)).join()}');
      await tester.pump(const Duration(milliseconds: 200));
    }
  });
}
""",
    "lib/transitions.dart": """import 'package:material_ui/material_ui.dart';

import 'motion/motion.dart';

// {w_c_transition}
class FadeSlideTransitions extends PageTransitionsBuilder {
  const FadeSlideTransitions();

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondary, Widget child) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    final curved = CurvedAnimation(parent: animation, curve: Motion.enter, reverseCurve: Motion.exit);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(position: Tween(begin: const Offset(0.15, 0), end: Offset.zero).animate(curved), child: child),
    );
  }
}

ThemeData themed(ThemeData base) => base.copyWith(
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {TargetPlatform.android: FadeSlideTransitions(), TargetPlatform.iOS: FadeSlideTransitions()},
  ),
);

class StepPage extends StatelessWidget {
  const StepPage({super.key, required this.n});

  final int n;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('$n')),
    body: Center(
      child: FilledButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => StepPage(n: n + 1))),
        child: const Text('{w_next}'),
      ),
    ),
  );
}
""",
    "test/transition_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/transitions.dart';

Future<double?> opacityHalfway(WidgetTester tester, {required bool reduced}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: MaterialApp(key: ValueKey(reduced), theme: themed(ThemeData()), home: const StepPage(n: 1)),
    ),
  );
  await tester.tap(find.byType(FilledButton));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 150));
  final fades = find.ancestor(of: find.text('2'), matching: find.byType(FadeTransition));
  return fades.evaluate().isEmpty ? null : tester.widget<FadeTransition>(fades.first).opacity.value;
}

void main() {
  testWidgets('{w_t_transition}', (tester) async {
    final normal = await opacityHalfway(tester, reduced: false);
    final reduced = await opacityHalfway(tester, reduced: true);
    debugPrint('halfway through the push: normal ${normal?.toStringAsFixed(2)}, reduced motion: ${reduced ?? 'no fade at all'}');
    expect(normal, inExclusiveRange(0, 1));
    expect(reduced, isNull);
  });
}
""",
}

SHOTS = [
    ("card-film.png", "lib/order_card_slow.dart", "button={w_add}|film=0,250,500,900,1500,3200"),
    ("brewing.png", "lib/brewing.dart", "wait=700"),
    ("hero-film.png", "lib/hero_menu_slow.dart", "text={w_latte}|film=0,300,700,1200,1800,3500"),
    ("stagger-film.png", "lib/stagger_slow.dart", "button={w_replay}|film=0,1000,2000,3000,4500,8500"),
]

TESTS = [
    ("curves-test.sh", "test/curves_test.dart"),
    ("implicit-test.sh", "test/implicit_test.dart"),
    ("child-test.sh", "test/child_test.dart"),
    ("reduce-test.sh", "test/reduce_test.dart"),
    ("projects/badge-test.sh", "test/badge_test.dart"),
    ("projects/stagger-test.sh", "test/stagger_test.dart"),
    ("projects/transition-test.sh", "test/transition_test.dart"),
]


def strips():
    """Each filmstrip: the six frames in two rows of three, at half size, then the frames removed."""
    for lang in T:
        shots = HERE / lang / "shots"
        for name in ("card-film", "hero-film", "stagger-film"):
            frames = [Image.open(shots / f"{name}-{k}.png") for k in range(1, 7)]
            w, h = frames[0].size
            crop = h // 2 if name == "card-film" else h
            gap, fw, fh = 16, w // 2, crop // 2
            strip = Image.new("RGB", (fw * 3 + gap * 2, fh * 2 + gap), "white")
            for k, frame in enumerate(frames):
                strip.paste(frame.crop((0, 0, w, crop)).resize((fw, fh)), ((k % 3) * (fw + gap), (k // 3) * (fh + gap)))
            strip.save(shots / f"{name}.png")
            for k in range(1, 7):
                (shots / f"{name}-{k}.png").unlink()


def main():
    flutter_gallery(HERE, T, FILES, SHOTS, TESTS)
    strips()


if __name__ == "__main__":
    main()
