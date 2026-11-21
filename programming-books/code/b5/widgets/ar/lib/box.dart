import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const BoxApp());
}

class BoxApp extends StatelessWidget {
  const BoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey.shade200,
        body: Center(
          // Container: الحجم، والمسافة داخله وخارجه، والزخرفة.
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(16),
            // زوايا مستديرة، وإطار، وظل خفيف.
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
                Text('صندوق أنيق', style: TextStyle(fontSize: 24)),
                SizedBox(height: 8),
                Text(
                  'حشوة في الداخل، وهامش في الخارج',
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
