import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DirectionsPage(),
    ),
  );
}

class DirectionsPage extends StatelessWidget {
  const DirectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('اتجاهان')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final direction in TextDirection.values) ...[
            Text(
              direction == TextDirection.ltr
                  ? 'من اليسار إلى اليمين'
                  : 'من اليمين إلى اليسار',
            ),
            Directionality(
              textDirection: direction,
              child: Column(
                children: [
                  // left: على اليسار دائماً، أياً كانت اللغة.
                  Card(
                    color: colors.errorContainer,
                    child: const Padding(
                      padding: EdgeInsets.only(
                        left: 48,
                        top: 16,
                        bottom: 16,
                        right: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_cafe),
                          SizedBox(width: 8),
                          Expanded(child: Text('left: 48')),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ),
                  // start: على اليسار بالإنجليزية، وعلى اليمين بالعربية.
                  Card(
                    color: colors.primaryContainer,
                    child: const Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: 48,
                        top: 16,
                        bottom: 16,
                        end: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_cafe),
                          SizedBox(width: 8),
                          Expanded(child: Text('start: 48')),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}
