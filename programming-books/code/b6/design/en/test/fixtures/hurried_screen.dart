import 'package:material_ui/material_ui.dart';

class HurriedScreen extends StatelessWidget {
  const HurriedScreen({super.key});

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFF3EDE7),
    padding: const EdgeInsets.all(12),
    child: const Text(
      'Sale!',
      style: TextStyle(fontSize: 22, color: Colors.red),
    ),
  );
}
