import 'package:material_ui/material_ui.dart';

var chartPaints = 0;

class SalesChart extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    chartPaints++;
    final paint = Paint()..color = Colors.brown;
    for (var i = 0; i < 24; i++) {
      final h = size.height * (0.2 + (i * 37 % 80) / 100);
      canvas.drawRect(
        Rect.fromLTWH(i * size.width / 24, size.height - h, size.width / 30, h),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(SalesChart old) => false;
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key, required this.boundary});

  final bool boundary;

  @override
  Widget build(BuildContext context) {
    final chart = CustomPaint(
      size: const Size(300, 160),
      painter: SalesChart(),
    );
    return Scaffold(
      body: Column(
        children: [
          const LinearProgressIndicator(),
          // المؤشر يُعاد رسمه ستين مرة في الثانية؛ والحد يُبقي الرسم البياني خارج ذلك.
          if (boundary) RepaintBoundary(child: chart) else chart,
        ],
      ),
    );
  }
}
