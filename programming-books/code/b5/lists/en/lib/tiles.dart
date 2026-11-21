import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Bit Café')),
        // ListView: a column that scrolls when its children do not fit.
        body: ListView(
          children: const [
            ListTile(
              leading: Icon(Icons.schedule),
              title: Text('Opening hours'),
              subtitle: Text('Every day, 8:00 to 22:00'),
            ),
            ListTile(
              leading: Icon(Icons.place),
              title: Text('Address'),
              subtitle: Text('12 Nile Street, Cairo'),
            ),
            ListTile(
              leading: Icon(Icons.wifi),
              title: Text('Wi-Fi'),
              subtitle: Text('Free for customers'),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            ),
          ],
        ),
      ),
    ),
  );
}
