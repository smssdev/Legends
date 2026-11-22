"""Writes the examples of Book 6, chapter "How Flutter Really Renders", in English and Arabic, photographs
them after real taps, and runs their tests (which count builds and paints, and print the three trees).
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
        w_t_trees="the three trees of a small screen",
        w_c_walk="Every element, from the Directionality down, with its widget and its render object.",
        w_c_ro="Only a RenderObjectElement owns a render object; the others only build widgets.",
        w_lifted="State in the page", w_pushed="State pushed down", w_plus="Add one",
        w_builds="builds", w_count="Count",
        w_c_counter="Counts how many times each widget's build method ran.",
        w_c_const="const: the same object every time, so Flutter skips it.",
        w_c_plain="Not const: a new object on every build of its parent, so it builds again.",
        w_c_local="Its own state: setState here rebuilds only this widget.",
        w_t_rebuilds="setState rebuilds the widget and everything new below it",
        w_constraints="Constraints", w_c_label="Shows the constraints this spot received from its parent.",
        w_tight="Inside SizedBox(300 × 56)", w_loose="Inside Center, inside the same box",
        w_expanded="Inside Expanded, in a Row", w_list="Inside a vertical ListView",
        w_c_container="Asks for 100 wide, but the parent is tight: it gets 300.",
        w_asked="Container(width: 100) in a tight 300",
        w_keys="Keys", w_nokeys="Without keys", w_withkeys="With ValueKey", w_swap="Swap",
        w_tap="Tap",
        w_c_nokey="No key: after a swap, each State stays at its position.",
        w_c_key="A key: each State follows its widget.",
        w_t_keys="without keys the state stays behind; with keys it moves",
        w_t_paint="a boundary stops the static painting from repainting",
        w_c_painter="Counts its paints: a picture that never changes should be painted once.",
        w_c_spinner="Repaints every frame.",
        w_c_boundary="A layer of its own: repainting the spinner no longer repaints its neighbours.",
        # Projects
        w_t_tile="a ListTile is many elements and few render objects",
        w_t_order="reordering keeps the state of each task",
        w_order="Tasks", w_a="Write tests", w_b="Fix the bug", w_c="Ship it", w_done="done",
        w_c_reorder="ValueKey(task): the State follows the task when it moves.",
        w_t_budget="the clock repaints only itself",
        w_c_budget="A budget: if anything else repaints, the test fails and says how often.",
    ),
    "ar": dict(
        w_rtl="// من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.\n"
              "builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),\n",
        w_t_trees="الأشجار الثلاث لشاشة صغيرة",
        w_c_walk="كل عنصر، من Directionality إلى الأسفل، مع الـ Widget وكائن الرسم الخاصين به.",
        w_c_ro="RenderObjectElement وحده يملك كائن رسم؛ والباقي يبني Widgets فقط.",
        w_lifted="الحالة في الصفحة", w_pushed="الحالة أُنزلت إلى أسفل", w_plus="أضف واحداً",
        w_builds="مرات البناء", w_count="العدد",
        w_c_counter="يعدّ كم مرة نُفّذت دالة build في كل Widget.",
        w_c_const="const: الكائن نفسه في كل مرة، فيتخطاه Flutter.",
        w_c_plain="بلا const: كائن جديد مع كل بناء لأبيه، فيُبنى من جديد.",
        w_c_local="حالته الخاصة: setState هنا تعيد بناء هذا الـ Widget وحده.",
        w_t_rebuilds="setState تعيد بناء الـ Widget وكل جديد تحته",
        w_constraints="القيود", w_c_label="يعرض القيود التي تلقّاها هذا المكان من أبيه.",
        w_tight="داخل SizedBox(300 × 56)", w_loose="داخل Center، داخل الصندوق نفسه",
        w_expanded="داخل Expanded، في Row", w_list="داخل ListView عمودية",
        w_c_container="يطلب عرض 100، لكن الأب صارم: فيأخذ 300.",
        w_asked="Container(width: 100) في 300 صارمة",
        w_keys="المفاتيح", w_nokeys="بلا مفاتيح", w_withkeys="مع ValueKey", w_swap="بدّل",
        w_tap="المس",
        w_c_nokey="بلا مفتاح: بعد التبديل تبقى كل State في موضعها.",
        w_c_key="مع مفتاح: كل State تتبع الـ Widget الخاص بها.",
        w_t_keys="بلا مفاتيح تبقى الحالة مكانها؛ ومع المفاتيح تنتقل",
        w_t_paint="الحد يمنع الرسمة الثابتة من إعادة الرسم",
        w_c_painter="يعدّ مرات رسمه: صورة لا تتغير يجب أن تُرسم مرة واحدة.",
        w_c_spinner="يعيد الرسم مع كل إطار.",
        w_c_boundary="طبقة خاصة به: إعادة رسم المؤشر لم تعد تعيد رسم جيرانه.",
        w_t_tile="ListTile عناصر كثيرة وكائنات رسم قليلة",
        w_t_order="إعادة الترتيب تُبقي حالة كل عدّاد",
        w_order="المهام", w_a="اكتب الاختبارات", w_b="أصلح الخطأ", w_c="انشره", w_done="تم",
        w_c_reorder="ValueKey(task): الـ State تتبع المهمة حين تتحرك.",
        w_t_budget="الساعة تعيد رسم نفسها فقط",
        w_c_budget="ميزانية: إن أعاد شيء آخر الرسم فشل الاختبار وقال كم مرة.",
    ),
}

APP = """void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      {w_rtl}
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
      home: const %s(),
    ),
  );
}
"""

FILES = {
    "test/trees_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('{w_t_trees}', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: Padding(padding: EdgeInsets.all(8), child: Text('Bit'))),
      ),
    );
    // {w_c_walk}
    final root = tester.element(find.byType(Directionality));
    void show(Element e, int depth) {
      // {w_c_ro}
      final ro = e is RenderObjectElement ? '${e.renderObject.runtimeType}' : '-';
      debugPrint('${'  ' * depth}${e.widget.runtimeType} | ${e.runtimeType} | $ro');
      e.visitChildren((child) => show(child, depth + 1));
    }

    show(root, 0);
  });
}
""",
    "lib/rebuilds.dart": """import 'package:material_ui/material_ui.dart';

// {w_c_counter}
final builds = <String, int>{};

int counted(String name) => builds[name] = (builds[name] ?? 0) + 1;

""" + APP % "RebuildsPage" + """
class RebuildsPage extends StatefulWidget {
  const RebuildsPage({super.key});

  @override
  State<RebuildsPage> createState() => _RebuildsPageState();
}

class _RebuildsPageState extends State<RebuildsPage> {
  var count = 0;

  @override
  Widget build(BuildContext context) {
    final page = counted('page');
    return Scaffold(
      appBar: AppBar(title: const Text('{w_lifted}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(title: const Text('RebuildsPage'), trailing: Text('$page {w_builds}')),
          // {w_c_const}
          const Badge1(),
          // {w_c_plain}
          Badge2(),
          FilledButton(onPressed: () => setState(() => count++), child: Text('{w_plus} ($count)')),
          const Divider(height: 32),
          Text('{w_pushed}', style: Theme.of(context).textTheme.titleMedium),
          const LocalCounter(),
        ],
      ),
    );
  }
}

class Badge1 extends StatelessWidget {
  const Badge1({super.key});

  @override
  Widget build(BuildContext context) =>
      ListTile(title: const Text('const Badge1'), trailing: Text('${counted('const')} {w_builds}'));
}

class Badge2 extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  Badge2({super.key});

  @override
  Widget build(BuildContext context) =>
      ListTile(title: const Text('Badge2'), trailing: Text('${counted('plain')} {w_builds}'));
}

// {w_c_local}
class LocalCounter extends StatefulWidget {
  const LocalCounter({super.key});

  @override
  State<LocalCounter> createState() => _LocalCounterState();
}

class _LocalCounterState extends State<LocalCounter> {
  var count = 0;

  @override
  Widget build(BuildContext context) {
    final mine = counted('local');
    return Column(
      children: [
        ListTile(title: const Text('LocalCounter'), trailing: Text('$mine {w_builds}')),
        OutlinedButton(onPressed: () => setState(() => count++), child: Text('{w_plus} ($count)')),
      ],
    );
  }
}
""",
    "test/rebuilds_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/rebuilds.dart';

void main() {
  testWidgets('{w_t_rebuilds}', (tester) async {
    builds.clear();
    await tester.pumpWidget(const MaterialApp(home: RebuildsPage()));
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
    }
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();
    }
    debugPrint('$builds');
    expect(builds, {'page': 4, 'const': 1, 'plain': 4, 'local': 6});
  });
}
""",
    "lib/constraints.dart": """import 'package:material_ui/material_ui.dart';

""" + APP % "ConstraintsPage" + """
String describe(BoxConstraints c) {
  String range(double min, double max) =>
      min == max ? min.toStringAsFixed(0) : '${min.toStringAsFixed(0)}–${max.isFinite ? max.toStringAsFixed(0) : '∞'}';
  return 'w ${range(c.minWidth, c.maxWidth)}   h ${range(c.minHeight, c.maxHeight)}';
}

// {w_c_label}
class ConstraintsLabel extends StatelessWidget {
  const ConstraintsLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ColoredBox(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(describe(constraints), textDirection: TextDirection.ltr),
        ),
      ),
    );
  }
}

class ConstraintsPage extends StatelessWidget {
  const ConstraintsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final examples = [
      ('{w_tight}', const SizedBox(width: 300, height: 56, child: ConstraintsLabel())),
      ('{w_loose}', const SizedBox(width: 300, height: 56, child: Center(child: ConstraintsLabel()))),
      ('{w_expanded}', const Row(children: [Expanded(child: ConstraintsLabel()), SizedBox(width: 120)])),
      ('{w_list}', SizedBox(height: 56, child: ListView(children: const [ConstraintsLabel()]))),
      (
        '{w_asked}',
        SizedBox(
          width: 300,
          height: 56,
          // {w_c_container}
          child: Container(width: 100, color: Colors.amber, child: const ConstraintsLabel()),
        ),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('{w_constraints}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (label, child) in examples) ...[
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Align(alignment: AlignmentDirectional.centerStart, child: child),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
""",
    "lib/keys.dart": """import 'package:material_ui/material_ui.dart';

""" + APP % "KeysPage" + """
class Tile extends StatefulWidget {
  const Tile({super.key, required this.label});

  final String label;

  @override
  State<Tile> createState() => _TileState();
}

class _TileState extends State<Tile> {
  var taps = 0;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: InkWell(
          onTap: () => setState(() => taps++),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(widget.label, style: Theme.of(context).textTheme.headlineMedium),
                Text('{w_tap}: $taps'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class KeysPage extends StatefulWidget {
  const KeysPage({super.key});

  @override
  State<KeysPage> createState() => _KeysPageState();
}

class _KeysPageState extends State<KeysPage> {
  var labels = ['A', 'B'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{w_keys}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('{w_nokeys}', style: Theme.of(context).textTheme.titleMedium),
          // {w_c_nokey}
          Row(children: [for (final l in labels) Tile(label: l)]),
          const SizedBox(height: 24),
          Text('{w_withkeys}', style: Theme.of(context).textTheme.titleMedium),
          // {w_c_key}
          Row(children: [for (final l in labels) Tile(key: ValueKey(l), label: l)]),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => setState(() => labels = labels.reversed.toList()),
            icon: const Icon(Icons.swap_horiz),
            label: const Text('{w_swap}'),
          ),
        ],
      ),
    );
  }
}
""",
    "test/keys_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/keys.dart';

void main() {
  testWidgets('{w_t_keys}', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: KeysPage()));
    // {w_c_tap3}
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('A').first);
      await tester.tap(find.text('A').last);
      await tester.pump();
    }
    await tester.tap(find.text('{w_swap}'));
    await tester.pump();

    String tapsUnder(Finder label) =>
        (tester.widget<Text>(find.descendant(of: find.ancestor(of: label, matching: find.byType(Column)), matching: find.textContaining(':')))).data!;
    // {w_c_without}
    expect(tapsUnder(find.text('A').first), '{w_tap}: 0');
    // {w_c_with}
    expect(tapsUnder(find.text('A').last), '{w_tap}: 3');
  });
}
""",
    "test/repaint_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// {w_c_painter}
class CountingPainter extends CustomPainter {
  var paints = 0;

  @override
  void paint(Canvas canvas, Size size) {
    paints++;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF7C4DFF));
  }

  @override
  bool shouldRepaint(CountingPainter old) => false;
}

class Spinner extends StatefulWidget {
  const Spinner({super.key});

  @override
  State<Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<Spinner> with SingleTickerProviderStateMixin {
  late final turns = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();

  @override
  void dispose() {
    turns.dispose();
    super.dispose();
  }

  // {w_c_spinner}
  @override
  Widget build(BuildContext context) => RotationTransition(turns: turns, child: const FlutterLogo(size: 40));
}

Future<int> paintsOver60Frames(WidgetTester tester, {required bool boundary}) async {
  final painter = CountingPainter();
  final picture = CustomPaint(painter: painter, size: const Size(100, 100));
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          picture,
          // {w_c_boundary}
          if (boundary) const RepaintBoundary(child: Spinner()) else const Spinner(),
        ],
      ),
    ),
  );
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  return painter.paints;
}

void main() {
  testWidgets('{w_t_paint}', (tester) async {
    final without = await paintsOver60Frames(tester, boundary: false);
    final withBoundary = await paintsOver60Frames(tester, boundary: true);
    debugPrint('without a boundary: $without paints, with one: $withBoundary');
    expect(withBoundary, 1);
  });
}
""",
    # Projects
    "test/tile_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('{w_t_tile}', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: ListTile(leading: Icon(Icons.star), title: Text('Bit'), trailing: Icon(Icons.chevron_right)),
        ),
      ),
    );
    final tile = tester.element(find.byType(ListTile));
    var elements = 0;
    final renderObjects = <String>[];
    void walk(Element e) {
      elements++;
      if (e is RenderObjectElement) {
        renderObjects.add('${e.renderObject.runtimeType}');
      }
      e.visitChildren(walk);
    }

    walk(tile);
    debugPrint('$elements elements, ${renderObjects.length} render objects:');
    debugPrint(renderObjects.join(', '));
    expect(renderObjects.length, lessThan(elements));
  });
}
""",
    "projects/reorder.dart": """import 'package:material_ui/material_ui.dart';

""" + APP % "TasksPage" + """
class TaskTile extends StatefulWidget {
  const TaskTile({super.key, required this.task});

  final String task;

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  var done = false;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(widget.task),
      subtitle: done ? const Text('{w_done}') : null,
      value: done,
      onChanged: (v) => setState(() => done = v ?? false),
    );
  }
}

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final tasks = ['{w_a}', '{w_b}', '{w_c}'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{w_order}')),
      body: ReorderableListView(
        onReorderItem: (from, to) => setState(() => tasks.insert(to, tasks.removeAt(from))),
        children: [
          // {w_c_reorder}
          for (final task in tasks) TaskTile(key: ValueKey(task), task: task),
        ],
      ),
    );
  }
}
""",
    "test/reorder_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_reorder.dart';

void main() {
  testWidgets('{w_t_order}', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TasksPage()));
    await tester.tap(find.text('{w_a}'));
    await tester.pump();

    // {w_c_drag}
    final gesture = await tester.startGesture(tester.getCenter(find.text('{w_a}')));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(0, 200));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final titles = [for (final t in tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile))) (t.title! as Text).data];
    expect(titles.last, '{w_a}');
    final moved = tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, '{w_a}'));
    expect(moved.value, isTrue);
  });
}
""",
    "test/budget_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class CountingPainter extends CustomPainter {
  CountingPainter(this.name, this.counts);

  final String name;
  final Map<String, int> counts;

  @override
  void paint(Canvas canvas, Size size) {
    counts[name] = (counts[name] ?? 0) + 1;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF7C4DFF));
  }

  @override
  bool shouldRepaint(CountingPainter old) => false;
}

class Clock extends StatefulWidget {
  const Clock({super.key, required this.counts});

  final Map<String, int> counts;

  @override
  State<Clock> createState() => _ClockState();
}

class _ClockState extends State<Clock> with SingleTickerProviderStateMixin {
  late final ticks = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();

  @override
  void dispose() {
    ticks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ticks,
    builder: (context, _) => CustomPaint(painter: _Hand(ticks.value, widget.counts), size: const Size(60, 60)),
  );
}

class _Hand extends CustomPainter {
  _Hand(this.value, this.counts);

  final double value;
  final Map<String, int> counts;

  @override
  void paint(Canvas canvas, Size size) {
    counts['clock'] = (counts['clock'] ?? 0) + 1;
    canvas.drawCircle(size.center(Offset.zero), size.width / 2 * value, Paint());
  }

  @override
  bool shouldRepaint(_Hand old) => old.value != value;
}

Widget dashboard(Map<String, int> counts) => Directionality(
  textDirection: TextDirection.ltr,
  child: Column(
    children: [
      CustomPaint(painter: CountingPainter('header', counts), size: const Size(200, 40)),
      Row(
        children: [
          CustomPaint(painter: CountingPainter('chart', counts), size: const Size(120, 80)),
          // {w_c_budget}
          RepaintBoundary(child: Clock(counts: counts)),
        ],
      ),
      CustomPaint(painter: CountingPainter('footer', counts), size: const Size(200, 40)),
    ],
  ),
);

void main() {
  testWidgets('{w_t_budget}', (tester) async {
    final counts = <String, int>{};
    await tester.pumpWidget(dashboard(counts));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    debugPrint('$counts');
    final others = {...counts}..remove('clock');
    expect(others.values.every((n) => n == 1), isTrue, reason: 'repainted: $others');
  });
}
""",
}

# The same dashboard before the fix: no RepaintBoundary around the clock, so the budget test fails.
FILES["test/budget_before_test.dart"] = FILES["test/budget_test.dart"].replace(
    "          // {w_c_budget}\n          RepaintBoundary(child: Clock(counts: counts)),", "          Clock(counts: counts),")
assert FILES["test/budget_before_test.dart"] != FILES["test/budget_test.dart"]


def failure(lines):
    """The failing run, without the stack trace."""
    keep = [l for l in lines if l.startswith(("00:", "{", "repainted", "Expected", "  Actual", "$"))]
    return keep[:7]


SHOTS = [
    ("rebuilds.png", "lib/rebuilds.dart",
     "button={w_plus} (0)|button={w_plus} (1)|button={w_plus} (2)|wait=500|" + "|".join(["at=195,367"] * 5)),
    ("constraints.png", "lib/constraints.dart", ""),
    ("keys-before.png", "lib/keys.dart", ""),
    ("keys-after.png", "lib/keys.dart", "at={w_xa},130|at={w_xa},130|at={w_xa},130|at={w_xa},280|at={w_xa},280|at={w_xa},280|button={w_swap}"),
    ("reorder.png", "projects/reorder.dart", ""),
]

T["en"].update(w_c_tap3="Tap A three times in both rows.",
               w_c_without="Without keys: A moved to the other side, but its 3 taps stayed where they were.",
               w_c_with="With keys: the 3 taps of A moved with it.",
               w_c_drag="On a phone, a long press picks the task up; then drag it below the last one.")
T["ar"].update(w_c_tap3="المس A ثلاث مرات في الصفين.",
               w_c_without="بلا مفاتيح: انتقل A إلى الجهة الأخرى، لكن لمساته الثلاث بقيت مكانها.",
               w_c_with="مع المفاتيح: انتقلت لمسات A الثلاث معه.",
               w_c_drag="على الجوال، الضغط المطوّل يرفع المهمة؛ ثم اسحبها تحت الأخيرة.")
T["en"]["w_xa"] = "100"
T["ar"]["w_xa"] = "290"

TESTS = [
    ("trees-test.sh", "test/trees_test.dart"),
    ("rebuilds-test.sh", "test/rebuilds_test.dart"),
    ("keys-test.sh", "test/keys_test.dart"),
    ("repaint-test.sh", "test/repaint_test.dart"),
    ("projects/tile-test.sh", "test/tile_test.dart"),
    ("projects/reorder-test.sh", "test/reorder_test.dart"),
    ("projects/budget-before.sh", "test/budget_before_test.dart", failure),
    ("projects/budget-test.sh", "test/budget_test.dart"),
]


def main():
    flutter_gallery(HERE, T, FILES, SHOTS, TESTS)


if __name__ == "__main__":
    main()
