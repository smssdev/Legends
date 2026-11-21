import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: const Onboarding(),
    ),
  );
}

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final controller = PageController();
  int page = 0;

  static const pages = [
    (Icons.phone_iphone, 'اطلب مسبقاً', 'اختر مشروبك قبل أن تصل.'),
    (Icons.directions_walk, 'تجاوز الطابور', 'كوبك جاهز حين تدخل.'),
    (Icons.card_giftcard, 'اجمع النقاط', 'كل قهوة عاشرة على حسابنا.'),
  ];

  void finish() {
    // pushReplacement: تختفي صفحات التعريف؛ والرجوع لا يعود إليها.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const Scaffold(body: Center(child: Text('أهلاً بك في مقهى بِت'))),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = page == pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(onPressed: finish, child: const Text('تخطَّ')),
            ),
            // PageView: صفحات كاملة تُسحب جانباً؛ والمتحكم يحركها بالكود.
            Expanded(
              child: PageView(
                controller: controller,
                onPageChanged: (i) => setState(() => page = i),
                children: [
                  for (final (icon, title, text) in pages)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 12,
                        children: [
                          Icon(icon, size: 120, color: Colors.brown),
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(text, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(4),
                    width: i == page ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == page ? Colors.brown : Colors.brown.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: last
                      ? finish
                      : () => controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        ),
                  child: Text(last ? 'ابدأ' : 'التالي'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
