import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('مقهى بِت')),
        // ListView: عمود يتمرر حين لا يتسع لأبنائه.
        body: ListView(
          children: const [
            ListTile(
              leading: Icon(Icons.schedule),
              title: Text('مواعيد العمل'),
              subtitle: Text('كل يوم، من 8:00 إلى 22:00'),
            ),
            ListTile(
              leading: Icon(Icons.place),
              title: Text('العنوان'),
              subtitle: Text('12 شارع النيل، القاهرة'),
            ),
            ListTile(
              leading: Icon(Icons.wifi),
              title: Text('واي فاي'),
              subtitle: Text('مجاني للزبائن'),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            ),
          ],
        ),
      ),
    ),
  );
}
