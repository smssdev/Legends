import 'package:material_ui/material_ui.dart';

// Every Dart program starts by running main().
void main() {
  runApp(const HelloBitApp());
}

// The whole app is one widget: a description of what to show.
class HelloBitApp extends StatelessWidget {
  const HelloBitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hello Bit',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Hello Bit'),
          centerTitle: true,
          // The colour of the bar, and of the text on it.
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Hello, Flutter!', style: TextStyle(fontSize: 32)),
        ),
      ),
    );
  }
}
