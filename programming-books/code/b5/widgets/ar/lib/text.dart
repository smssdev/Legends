import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const TextApp());
}

class TextApp extends StatelessWidget {
  const TextApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40),
              // الحجم والسُّمك واللون: كل ما يخص شكل النص في TextStyle.
              Text(
                'عرض اليوم',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              SizedBox(height: 8),
              // سطران على الأكثر، ثم ثلاث نقاط.
              Text(
                'لاتيه بحليب الشوفان وقطعة من كيك العسل، تُقدَّم طوال اليوم على المنضدة أو على طاولتك.',
                style: TextStyle(fontSize: 18, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Text(
                '45 جنيهاً',
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.teal,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
