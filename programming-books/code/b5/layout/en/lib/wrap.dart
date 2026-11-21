import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: const WrapPage()),
  );
}

class WrapPage extends StatelessWidget {
  const WrapPage({super.key});

  @override
  Widget build(BuildContext context) {
    const tags =
        'hot,iced,sweet,no sugar,oat milk,decaf,large,extra shot,to go';
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
        // Wrap: like a Row, but goes on to the next line when it is full.
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final tag in tags.split(',')) Chip(label: Text(tag))],
        ),
      ),
    );
  }
}
