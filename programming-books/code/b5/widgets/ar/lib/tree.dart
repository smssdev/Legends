import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const CafeApp());
}

class CafeApp extends StatelessWidget {
  const CafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('مقهى بِت')),
        body: const Center(
          // Column يضع أبناءه واحداً تحت الآخر.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_cafe, size: 80, color: Colors.brown),
              Text('مفتوح كل يوم', style: TextStyle(fontSize: 24)),
              Text('من 8:00 إلى 22:00'),
            ],
          ),
        ),
      ),
    );
  }
}
