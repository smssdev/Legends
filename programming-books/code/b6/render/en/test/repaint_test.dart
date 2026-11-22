import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Counts its paints: a picture that never changes should be painted once.
class CountingPainter extends CustomPainter {
  var paints = 0;

  @override
  void paint(Canvas canvas, Size size) {
    paints++;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF7C4DFF),
    );
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
  late final turns = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  @override
  void dispose() {
    turns.dispose();
    super.dispose();
  }

  // Repaints every frame.
  @override
  Widget build(BuildContext context) =>
      RotationTransition(turns: turns, child: const FlutterLogo(size: 40));
}

Future<int> paintsOver60Frames(
  WidgetTester tester, {
  required bool boundary,
}) async {
  final painter = CountingPainter();
  final picture = CustomPaint(painter: painter, size: const Size(100, 100));
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          picture,
          // A layer of its own: repainting the spinner no longer repaints its neighbours.
          if (boundary)
            const RepaintBoundary(child: Spinner())
          else
            const Spinner(),
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
  testWidgets('a boundary stops the static painting from repainting', (
    tester,
  ) async {
    final without = await paintsOver60Frames(tester, boundary: false);
    final withBoundary = await paintsOver60Frames(tester, boundary: true);
    debugPrint('without a boundary: $without paints, with one: $withBoundary');
    expect(withBoundary, 1);
  });
}
