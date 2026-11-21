import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: const GridPage()),
  );
}

class GridPage extends StatelessWidget {
  const GridPage({super.key});

  @override
  Widget build(BuildContext context) {
    const drinks = 'Latte,Tea,Mocha,Juice,Water,Cocoa,Espresso,Smoothie';
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const gap = 12.0;
            final columns = (constraints.maxWidth / 180).floor().clamp(2, 6);
            final tile = (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final name in drinks.split(','))
                  Container(
                    width: tile,
                    height: tile * 0.75,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.brown.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_cafe, size: 36),
                        Text(name),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
