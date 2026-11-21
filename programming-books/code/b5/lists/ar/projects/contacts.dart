import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: const ContactsPage(),
    ),
  );
}

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final names =
        'سارة أحمد,عمر خالد,منى عادل,أحمد سمير,ليلى حسن,يوسف نبيل,هنا مصطفى,كريم فتحي'
            .split(',')
          ..sort();
    return Scaffold(
      appBar: AppBar(title: Text('جهات الاتصال (${names.length})')),
      body: ListView.separated(
        itemCount: names.length,
        separatorBuilder: (context, i) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, i) => ListTile(
          leading: CircleAvatar(
            backgroundColor:
                Colors.primaries[i % Colors.primaries.length].shade100,
            child: Text(names[i][0]),
          ),
          title: Text(names[i]),
          trailing: const Icon(Icons.call),
        ),
      ),
    );
  }
}
