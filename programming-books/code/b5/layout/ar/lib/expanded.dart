import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: const ExpandedPage(),
    ),
  );
}

// مربع ملوّن برقم: هو نفسه في كل مثال.
class Box extends StatelessWidget {
  const Box(this.n, {super.key, this.size = 56});

  final int n;
  final double size;

  static const colors = [Colors.teal, Colors.orange, Colors.indigo];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: colors[(n - 1) % 3],
      child: Text(
        '$n',
        style: const TextStyle(color: Colors.white, fontSize: 22),
      ),
    );
  }
}

class ExpandedPage extends StatelessWidget {
  const ExpandedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 24,
          children: [
            // Expanded يأخذ المساحة الفارغة؛ وflex يقسمها.
            const Row(
              children: [
                Box(1),
                Expanded(child: Box(2)),
                Box(3),
              ],
            ),
            const Row(
              children: [
                Expanded(child: Box(1)),
                Expanded(flex: 2, child: Box(2)),
                Expanded(child: Box(3)),
              ],
            ),
            // Flexible: بالعرض الذي يحتاجه، لكن لا أعرض من المساحة الباقية.
            Row(
              children: [
                const Icon(Icons.local_cafe, size: 32),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'اسم طويل جداً لمشروب لا يتسع له سطر واحد في الشاشة',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 48, height: 32, color: Colors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
