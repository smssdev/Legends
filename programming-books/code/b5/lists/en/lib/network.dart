import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Scaffold(body: Center(child: Photo())),
    ),
  );
}

class Photo extends StatelessWidget {
  const Photo({super.key, this.url = 'https://example.com/latte.png'});

  final String url;

  @override
  Widget build(BuildContext context) {
    // A picture from the internet, with what to show while it loads and if it fails.
    return Image.network(
      url,
      width: 240,
      height: 180,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const SizedBox(
              width: 240,
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            ),
      errorBuilder: (context, error, stack) => Container(
        width: 240,
        height: 180,
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
      ),
    );
  }
}
