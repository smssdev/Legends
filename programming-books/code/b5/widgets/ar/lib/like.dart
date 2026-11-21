import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: const LikePage(),
    ),
  );
}

// StatefulWidget: الـ Widget، وكائن State يتذكر.
class LikePage extends StatefulWidget {
  const LikePage({super.key});

  @override
  State<LikePage> createState() => _LikePageState();
}

class _LikePageState extends State<LikePage> {
  int likes = 0;

  void like() {
    // setState: غيّر القيمة، ثم يستدعي Flutter دالة build من جديد.
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
              tooltip: 'أعجبني',
              onPressed: like,
              icon: Icon(
                likes > 0 ? Icons.favorite : Icons.favorite_border,
                color: Colors.red,
              ),
            ),
            Text('$likes إعجاب', style: const TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}
