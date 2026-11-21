import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const ButtonsApp());
}

class ButtonsApp extends StatelessWidget {
  const ButtonsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              FilledButton(onPressed: () {}, child: const Text('Order now')),
              OutlinedButton(
                onPressed: () {},
                child: const Text('See the menu'),
              ),
              TextButton(onPressed: () {}, child: const Text('Maybe later')),
              // onPressed: null turns a button off: it is drawn greyed out.
              const FilledButton(onPressed: null, child: Text('Coming soon')),
              // A Row puts its children side by side.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.favorite_border),
                  ),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.share)),
                  IconButton.filled(
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
