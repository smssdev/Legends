import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: const ResponsivePage(),
    ),
  );
}

class Panel extends StatelessWidget {
  const Panel(this.title, this.body, this.color, {super.key});

  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(body),
        ],
      ),
    );
  }
}

class ResponsivePage extends StatelessWidget {
  const ResponsivePage({super.key});

  @override
  Widget build(BuildContext context) {
    // MediaQuery: حجم الشاشة كلها، وكيف يُمسك الجهاز.
    final size = MediaQuery.sizeOf(context);
    final held = size.width > size.height ? 'أفقي' : 'عمودي';
    final menu = Panel('القائمة', 'لاتيه، شاي، كيك…', Colors.teal.shade100);
    final order = Panel('طلبك', '2 × لاتيه', Colors.orange.shade100);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'العرض ${size.width.round()}، الارتفاع ${size.height.round()}، $held',
            ),
            const SizedBox(height: 16),
            // LayoutBuilder يخبرنا كم مساحة لدينا؛ ونحن نختار التخطيط.
            LayoutBuilder(
              builder: (context, constraints) {
                // ضيق: عمود واحد. عريض: جنباً إلى جنب.
                if (constraints.maxWidth < 600) {
                  return Column(
                    spacing: 16,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [menu, order],
                  );
                }
                return Row(
                  spacing: 16,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: menu),
                    Expanded(child: order),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
