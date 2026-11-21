import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const ContactApp());
}

// Widget من صنعنا: أيقونة ونص، يُستخدم ثلاث مرات.
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
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('تواصل معنا')),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              InfoRow(icon: Icons.phone, text: '01001234567'),
              InfoRow(icon: Icons.email, text: 'hello@bitcafe.example'),
              InfoRow(icon: Icons.place, text: '12 شارع النيل، القاهرة'),
            ],
          ),
        ),
      ),
    );
  }
}
