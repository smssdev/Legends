import 'package:material_ui/material_ui.dart';

import 'motion/motion.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      // من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),

      theme: ThemeData(colorSchemeSeed: Colors.deepOrange),
      home: const StaggerPage(),
    ),
  );
}

const items = ['لاتيه', 'شاي بالنعناع', 'كيك الكرز', 'عصير برتقال'];

class StaggerPage extends StatefulWidget {
  const StaggerPage({super.key});

  @override
  State<StaggerPage> createState() => _StaggerPageState();
}

class _StaggerPageState extends State<StaggerPage>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller.duration = motion(context, const Duration(milliseconds: 800));
    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('القائمة'),
        actions: [
          IconButton(
            tooltip: 'أعد الحركة',
            icon: const Icon(Icons.replay),
            onPressed: () => controller.forward(from: 0),
          ),
        ],
      ),
      body: ListView(
        children: [
          for (final (i, name) in items.indexed)
            Builder(
              builder: (context) {
                // كل عنصر يبدأ بعد قليل: وInterval تعطي كلاً منها شريحته من المتحكم نفسه.
                final slice = CurvedAnimation(
                  parent: controller,
                  curve: Interval(
                    i * 0.15,
                    0.4 + i * 0.15,
                    curve: Motion.enter,
                  ),
                );
                return FadeTransition(
                  opacity: slice,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.6),
                      end: Offset.zero,
                    ).animate(slice),
                    child: Card(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: ListTile(title: Text(name)),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
