import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: const TabsPage(),
    ),
  );
}

class TabsPage extends StatelessWidget {
  const TabsPage({super.key});

  Widget list(List<String> items) =>
      ListView(children: [for (final i in items) ListTile(title: Text(i))]);

  @override
  Widget build(BuildContext context) {
    // TabBar وTabBarView، يبقيهما المتحكم متزامنين.
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مقهى بِت'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.local_cafe), text: 'المشروبات'),
              Tab(icon: Icon(Icons.bakery_dining), text: 'المأكولات'),
              Tab(icon: Icon(Icons.local_offer), text: 'العروض'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            list(['لاتيه', 'شاي بالنعناع', 'عصير برتقال']),
            list(['كيك الكرز', 'كوكيز', 'مافن']),
            list(['كوبا لاتيه بـ 80', 'كوكيز مجاناً يوم الجمعة']),
          ],
        ),
      ),
    );
  }
}
