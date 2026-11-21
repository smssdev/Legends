import 'package:material_ui/material_ui.dart';

// كل برنامج Dart يبدأ بتشغيل main().
void main() {
  runApp(const HelloBitApp());
}

// التطبيق كله Widget واحد: وصف لما يُعرض على الشاشة.
class HelloBitApp extends StatelessWidget {
  const HelloBitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مرحباً بِت',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('مرحباً بِت'),
          centerTitle: true,
          // لون الشريط، ولون النص عليه.
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('مرحباً يا Flutter!', style: TextStyle(fontSize: 32)),
        ),
      ),
    );
  }
}
