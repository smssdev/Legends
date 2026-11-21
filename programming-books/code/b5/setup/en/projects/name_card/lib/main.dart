import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const NameCardApp());
}

class NameCardApp extends StatelessWidget {
  const NameCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('My Card'),
          centerTitle: true,
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          // A Column puts its children one under the other (Chapter 6 explains it).
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person, size: 96, color: Colors.deepOrange),
              Text('Sara Ahmed', style: TextStyle(fontSize: 32)),
              // An empty box of 8 pixels: a gap between two lines.
              SizedBox(height: 8),
              Text(
                'Flutter developer in training',
                style: TextStyle(fontSize: 18),
              ),
              Text('Cairo, Egypt', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}
