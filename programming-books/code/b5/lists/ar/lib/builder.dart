import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('1000 طلب')),
        // builder: يطلب Flutter العنصر i فقط حين يوشك أن يظهر.
        body: ListView.builder(
          itemCount: 1000,
          itemBuilder: (context, i) => ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text('طلب رقم ${i + 1}'),
            subtitle: Text('${(i * 37) % 200 + 20} جنيه'),
          ),
        ),
      ),
    ),
  );
}
