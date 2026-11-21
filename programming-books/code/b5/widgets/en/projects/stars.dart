import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: const RatePage()),
  );
}

class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.value, required this.onChanged});

  final int value;
  // The widget tells its parent about a new rating through onChanged.
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // One star widget per value, 1 to 5.
        for (var i = 1; i <= 5; i++)
          IconButton(
            iconSize: 40,
            onPressed: () => onChanged(i),
            icon: Icon(
              i <= value ? Icons.star : Icons.star_border,
              color: Colors.amber,
            ),
          ),
      ],
    );
  }
}

class RatePage extends StatefulWidget {
  const RatePage({super.key});

  @override
  State<RatePage> createState() => _RatePageState();
}

class _RatePageState extends State<RatePage> {
  int rating = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Rate your coffee', style: TextStyle(fontSize: 24)),
            StarRating(
              value: rating,
              onChanged: (v) => setState(() => rating = v),
            ),
            Text(
              rating == 0 ? 'Tap a star' : '$rating out of 5',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
