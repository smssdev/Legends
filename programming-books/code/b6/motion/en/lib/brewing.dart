import 'dart:math';

import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(colorSchemeSeed: Colors.deepOrange),
      home: const BrewingPage(),
    ),
  );
}

var cupBuilds = 0;

class Cup extends StatelessWidget {
  const Cup({super.key});

  @override
  Widget build(BuildContext context) {
    cupBuilds++;
    return const Icon(Icons.local_cafe, size: 72);
  }
}

// Explicit: a controller drives the animation, here for ever, until the page closes.
class BrewingPage extends StatefulWidget {
  const BrewingPage({super.key});

  @override
  State<BrewingPage> createState() => _BrewingPageState();
}

class _BrewingPageState extends State<BrewingPage>
    with SingleTickerProviderStateMixin {
  late final turns = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    turns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('Brewing your latte')),
      body: Center(
        child: AnimatedBuilder(
          animation: turns,
          // The cup is built once and passed in; only the ring is rebuilt on each frame.
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
