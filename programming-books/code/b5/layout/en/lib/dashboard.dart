import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: const Dashboard()),
  );
}

class Stat extends StatelessWidget {
  const Stat(this.value, this.label, this.icon, {super.key});

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: Colors.brown),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class Section extends StatelessWidget {
  const Section(this.title, this.lines, {super.key});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            for (final line in lines) Text(line),
          ],
        ),
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    const popular = Section('Most popular', ['1. Latte', '2. Tea', '3. Cake']);
    const hours = Section('Opening hours', ['Every day, 8:00 to 22:00']);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The banner: a gradient, with the title pinned to its bottom.
          Container(
            height: 140,
            padding: const EdgeInsets.all(20),
            alignment: AlignmentDirectional.bottomStart,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Colors.brown, Colors.orange]),
            ),
            child: const Text(
              'Bit Café · Today',
              style: TextStyle(color: Colors.white, fontSize: 28),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              spacing: 12,
              children: [
                // Three cards share the width equally.
                const Row(
                  children: [
                    Expanded(child: Stat('48', 'orders', Icons.receipt_long)),
                    Expanded(child: Stat('2,160', 'sales', Icons.payments)),
                    Expanded(child: Stat('4.8', 'rating', Icons.star)),
                  ],
                ),
                // Two columns of sections on a wide screen, one on a phone.
                LayoutBuilder(
                  builder: (context, constraints) => constraints.maxWidth < 600
                      ? const Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [popular, hours],
                        )
                      : const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: popular),
                            Expanded(child: hours),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
