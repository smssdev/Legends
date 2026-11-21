import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: const StackPage()),
  );
}

class StackPage extends StatelessWidget {
  const StackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 40,
          children: [
            // Stack: children on top of each other; Positioned pins one to an edge.
            Stack(
              children: [
                Container(
                  width: 300,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.brown.shade300,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.coffee,
                    size: 96,
                    color: Colors.white,
                  ),
                ),
                PositionedDirectional(
                  top: 12,
                  start: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const PositionedDirectional(
                  bottom: 12,
                  start: 12,
                  end: 12,
                  child: Row(
                    children: [
                      Text(
                        'Pistachio latte',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      Spacer(),
                      Text(
                        '55 EGP',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // A badge on the corner of the cart icon.
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart, size: 56),
                Positioned(
                  top: -6,
                  right: -6,
                  child: CircleAvatar(
                    radius: 13,
                    backgroundColor: Colors.red,
                    child: const Text(
                      '3',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
