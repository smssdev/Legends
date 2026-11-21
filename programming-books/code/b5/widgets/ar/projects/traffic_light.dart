import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: const TrafficLight(),
    ),
  );
}

class TrafficLight extends StatefulWidget {
  const TrafficLight({super.key});

  @override
  State<TrafficLight> createState() => _TrafficLightState();
}

class _TrafficLightState extends State<TrafficLight> {
  int current = 0;

  // المصابيح الثلاثة بالترتيب؛ والمضاء منها ساطع.
  static const colors = [Colors.red, Colors.amber, Colors.green];
  static const labels = ['قف', 'استعد', 'انطلق'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إشارة المرور')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < 3; i++)
                    Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == current
                            ? colors[i]
                            : colors[i].withValues(alpha: 0.2),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(labels[current], style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => setState(() => current = (current + 1) % 3),
              child: const Text('التالي'),
            ),
          ],
        ),
      ),
    );
  }
}
