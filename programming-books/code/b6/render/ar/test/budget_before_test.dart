import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class CountingPainter extends CustomPainter {
  CountingPainter(this.name, this.counts);

  final String name;
  final Map<String, int> counts;

  @override
  void paint(Canvas canvas, Size size) {
    counts[name] = (counts[name] ?? 0) + 1;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF7C4DFF),
    );
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
  late final ticks = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  @override
  void dispose() {
    ticks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ticks,
    builder: (context, _) => CustomPaint(
      painter: _Hand(ticks.value, widget.counts),
      size: const Size(60, 60),
    ),
  );
}

class _Hand extends CustomPainter {
  _Hand(this.value, this.counts);

  final double value;
  final Map<String, int> counts;

  @override
  void paint(Canvas canvas, Size size) {
    counts['clock'] = (counts['clock'] ?? 0) + 1;
    canvas.drawCircle(
      size.center(Offset.zero),
      size.width / 2 * value,
      Paint(),
    );
  }

  @override
  bool shouldRepaint(_Hand old) => old.value != value;
}

Widget dashboard(Map<String, int> counts) => Directionality(
  textDirection: TextDirection.ltr,
  child: Column(
    children: [
      CustomPaint(
        painter: CountingPainter('header', counts),
        size: const Size(200, 40),
      ),
      Row(
        children: [
          CustomPaint(
            painter: CountingPainter('chart', counts),
            size: const Size(120, 80),
          ),
          Clock(counts: counts),
        ],
      ),
      CustomPaint(
        painter: CountingPainter('footer', counts),
        size: const Size(200, 40),
      ),
    ],
  ),
);

void main() {
  testWidgets('الساعة تعيد رسم نفسها فقط', (tester) async {
    final counts = <String, int>{};
    await tester.pumpWidget(dashboard(counts));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    debugPrint('$counts');
    final others = {...counts}..remove('clock');
    expect(
      others.values.every((n) => n == 1),
      isTrue,
      reason: 'repainted: $others',
    );
  });
}
