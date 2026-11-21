import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: const ContactsPage()),
  );
}

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final names =
        'Sara Ahmed,Omar Khaled,Mona Adel,Ahmed Samir,Laila Hassan,Youssef Nabil,Hana Mostafa,Karim Fathy'
            .split(',')
          ..sort();
    return Scaffold(
      appBar: AppBar(title: Text('Contacts (${names.length})')),
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
