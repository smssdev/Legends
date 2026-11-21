import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const BoxApp());
}

class BoxApp extends StatelessWidget {
  const BoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey.shade200,
        body: Center(
          // A Container: size, space inside and out, and a decoration.
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(16),
            // Rounded corners, a border and a soft shadow.
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.teal, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('A box with style', style: TextStyle(fontSize: 24)),
                SizedBox(height: 8),
                Text(
                  'padding inside, margin outside',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
