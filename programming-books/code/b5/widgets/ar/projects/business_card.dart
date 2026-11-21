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
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.indigo.shade50,
        body: Center(
          // Card: سطح بزوايا مستديرة وظل.
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
                    'سارة أحمد',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'مطوّرة تطبيقات',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const Divider(height: 32),
                  const InfoRow(icon: Icons.phone, text: '01001234567'),
                  const InfoRow(
                    icon: Icons.email,
                    text: 'hello@bitcafe.example',
                  ),
                  const InfoRow(icon: Icons.place, text: 'القاهرة، مصر'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
