import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: const TrafficLight()),
  );
}

class TrafficLight extends StatefulWidget {
  const TrafficLight({super.key});

  @override
  State<TrafficLight> createState() => _TrafficLightState();
}

class _TrafficLightState extends State<TrafficLight> {
  int current = 0;

  // The three lamps, in order; the one that is on is bright.
  static const colors = [Colors.red, Colors.amber, Colors.green];
  static const labels = ['Stop', 'Get ready', 'Go'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Traffic light')),
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
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
