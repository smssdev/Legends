import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: const WrapPage(),
    ),
  );
}

class WrapPage extends StatelessWidget {
  const WrapPage({super.key});

  @override
  Widget build(BuildContext context) {
    const tags =
        'ساخن,مثلج,حلو,بلا سكر,حليب الشوفان,منزوع الكافيين,كبير,جرعة إضافية,سفري';
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
        // Wrap: مثل Row، لكنه ينتقل إلى السطر التالي حين يمتلئ.
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final tag in tags.split(',')) Chip(label: Text(tag))],
        ),
      ),
    );
  }
}
