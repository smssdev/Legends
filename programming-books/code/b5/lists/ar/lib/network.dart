import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
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
    // صورة من الإنترنت، مع ما يُعرض أثناء تحميلها وإن فشلت.
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
