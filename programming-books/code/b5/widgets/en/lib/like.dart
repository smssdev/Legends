import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: const LikePage()),
  );
}

// A StatefulWidget: the widget, and a State object that remembers.
class LikePage extends StatefulWidget {
  const LikePage({super.key});

  @override
  State<LikePage> createState() => _LikePageState();
}

class _LikePageState extends State<LikePage> {
  int likes = 0;

  void like() {
    // setState: change the value, then Flutter calls build again.
    setState(() {
      likes++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              iconSize: 72,
              tooltip: 'Like',
              onPressed: like,
              icon: Icon(
                likes > 0 ? Icons.favorite : Icons.favorite_border,
                color: Colors.red,
              ),
            ),
            Text('$likes likes', style: const TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}
