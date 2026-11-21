import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const ContactApp());
}

// Our own widget: an icon and a text, used three times.
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

class ContactApp extends StatelessWidget {
  const ContactApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Contact us')),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              InfoRow(icon: Icons.phone, text: '0100 123 4567'),
              InfoRow(icon: Icons.email, text: 'hello@bitcafe.example'),
              InfoRow(icon: Icons.place, text: '12 Nile Street, Cairo'),
            ],
          ),
        ),
      ),
    );
  }
}
