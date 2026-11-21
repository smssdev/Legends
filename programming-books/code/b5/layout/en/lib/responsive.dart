import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const ResponsivePage(),
    ),
  );
}

class Panel extends StatelessWidget {
  const Panel(this.title, this.body, this.color, {super.key});

  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(body),
        ],
      ),
    );
  }
}

class ResponsivePage extends StatelessWidget {
  const ResponsivePage({super.key});

  @override
  Widget build(BuildContext context) {
    // MediaQuery: the size of the whole screen, and how it is held.
    final size = MediaQuery.sizeOf(context);
    final held = size.width > size.height ? 'landscape' : 'portrait';
    final menu = Panel('Menu', 'Latte, tea, cake…', Colors.teal.shade100);
    final order = Panel('Your order', '2 × Latte', Colors.orange.shade100);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'width ${size.width.round()}, height ${size.height.round()}, $held',
            ),
            const SizedBox(height: 16),
            // LayoutBuilder tells us how much room we have; we choose the layout.
            LayoutBuilder(
              builder: (context, constraints) {
                // Narrow: one column. Wide: side by side.
                if (constraints.maxWidth < 600) {
                  return Column(
                    spacing: 16,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [menu, order],
                  );
                }
                return Row(
                  spacing: 16,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: menu),
                    Expanded(child: order),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
