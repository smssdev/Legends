import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('1,000 orders')),
        // builder: Flutter asks for item i only when it is about to be seen.
        body: ListView.builder(
          itemCount: 1000,
          itemBuilder: (context, i) => ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text('Order #${i + 1}'),
            subtitle: Text('${(i * 37) % 200 + 20} EGP'),
          ),
        ),
      ),
    ),
  );
}
