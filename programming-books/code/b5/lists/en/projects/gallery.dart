import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: const GalleryPage()),
  );
}

const photos = ['latte', 'tea', 'juice', 'cake', 'cookie', 'muffin'];

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final selected = <int>{};

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          selected.isEmpty ? 'Photos' : '${selected.length} selected',
        ),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(8),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          for (var i = 0; i < photos.length; i++)
            GestureDetector(
              onTap: () => setState(
                () =>
                    selected.contains(i) ? selected.remove(i) : selected.add(i),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/${photos[i]}.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (selected.contains(i)) ...[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: scheme.primary, width: 4),
                      ),
                    ),
                    PositionedDirectional(
                      top: 8,
                      end: 8,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: scheme.primary,
                        child: Icon(
                          Icons.check,
                          size: 18,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
