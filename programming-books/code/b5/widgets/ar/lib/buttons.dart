import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const ButtonsApp());
}

class ButtonsApp extends StatelessWidget {
  const ButtonsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              FilledButton(onPressed: () {}, child: const Text('اطلب الآن')),
              OutlinedButton(
                onPressed: () {},
                child: const Text('اعرض القائمة'),
              ),
              TextButton(onPressed: () {}, child: const Text('ربما لاحقاً')),
              // onPressed: null تطفئ الزر: فيُرسم باهتاً.
              const FilledButton(onPressed: null, child: Text('قريباً')),
              // Row يضع أبناءه جنباً إلى جنب.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.favorite_border),
                  ),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.share)),
                  IconButton.filled(
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
