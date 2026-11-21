import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const TextApp());
}

class TextApp extends StatelessWidget {
  const TextApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40),
              // Size, weight and colour: everything a text looks like is in its TextStyle.
              Text(
                'Special of the day',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              SizedBox(height: 8),
              // Two lines at most, then three dots.
              Text(
                'A latte with oat milk and a slice of honey cake, served all day long at the counter or at your table.',
                style: TextStyle(fontSize: 18, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Text(
                '45 EGP',
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.teal,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
