import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const BusinessCardApp());
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class BusinessCardApp extends StatelessWidget {
  const BusinessCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.indigo.shade50,
        body: Center(
          // Card: a surface with rounded corners and a shadow.
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    child: Icon(Icons.person, size: 48),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sara Ahmed',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Flutter developer',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const Divider(height: 32),
                  const InfoRow(icon: Icons.phone, text: '0100 123 4567'),
                  const InfoRow(
                    icon: Icons.email,
                    text: 'hello@bitcafe.example',
                  ),
                  const InfoRow(icon: Icons.place, text: 'Cairo, Egypt'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
