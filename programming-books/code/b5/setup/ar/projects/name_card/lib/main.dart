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
          title: const Text('بطاقتي'),
          centerTitle: true,
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          // Column يضع أبناءه واحداً تحت الآخر (يشرحه الفصل 6).
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person, size: 96, color: Colors.deepOrange),
              Text('سارة أحمد', style: TextStyle(fontSize: 32)),
              // صندوق فارغ بارتفاع 8 بكسل: مسافة بين سطرين.
              SizedBox(height: 8),
              Text(
                'مطوّرة تطبيقات تحت التدريب',
                style: TextStyle(fontSize: 18),
              ),
              Text('القاهرة، مصر', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}
