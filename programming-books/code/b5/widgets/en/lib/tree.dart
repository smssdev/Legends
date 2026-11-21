import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const CafeApp());
}

class CafeApp extends StatelessWidget {
  const CafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Bit Café')),
        body: const Center(
          // A Column puts its children one under the other.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_cafe, size: 80, color: Colors.brown),
              Text('Open every day', style: TextStyle(fontSize: 24)),
              Text('8:00 to 22:00'),
            ],
          ),
        ),
      ),
    );
  }
}
