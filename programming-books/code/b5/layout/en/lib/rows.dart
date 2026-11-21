import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: const RowsPage()),
  );
}

// A coloured square with a number: the same in every example.
class Box extends StatelessWidget {
  const Box(this.n, {super.key, this.size = 56});

  final int n;
  final double size;

  static const colors = [Colors.teal, Colors.orange, Colors.indigo];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: colors[(n - 1) % 3],
      child: Text(
        '$n',
        style: const TextStyle(color: Colors.white, fontSize: 22),
      ),
    );
  }
}

class Labelled extends StatelessWidget {
  const Labelled(this.label, this.child, {super.key});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
        Container(color: Colors.grey.shade200, height: 80, child: child),
        const SizedBox(height: 16),
      ],
    );
  }
}

class RowsPage extends StatelessWidget {
  const RowsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const boxes = [Box(1), Box(2), Box(3)];
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        // The same three boxes, arranged four ways.
        child: Column(
          children: [
            Labelled('start', Row(children: boxes)),
            Labelled(
              'center',
              Row(mainAxisAlignment: MainAxisAlignment.center, children: boxes),
            ),
            Labelled(
              'spaceBetween',
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: boxes,
              ),
            ),
            Labelled(
              'spaceEvenly + cross end',
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: boxes,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
