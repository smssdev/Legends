import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: const Dashboard(),
    ),
  );
}

class Stat extends StatelessWidget {
  const Stat(this.value, this.label, this.icon, {super.key});

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: Colors.brown),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class Section extends StatelessWidget {
  const Section(this.title, this.lines, {super.key});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            for (final line in lines) Text(line),
          ],
        ),
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    const popular = Section('الأكثر طلباً', ['1. لاتيه', '2. شاي', '3. كيك']);
    const hours = Section('مواعيد العمل', ['كل يوم، من 8:00 إلى 22:00']);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // اللافتة: تدرّج لوني، والعنوان مثبّت في أسفلها.
          Container(
            height: 140,
            padding: const EdgeInsets.all(20),
            alignment: AlignmentDirectional.bottomStart,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Colors.brown, Colors.orange]),
            ),
            child: const Text(
              'مقهى بِت · اليوم',
              style: TextStyle(color: Colors.white, fontSize: 28),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              spacing: 12,
              children: [
                // ثلاث بطاقات تتقاسم العرض بالتساوي.
                const Row(
                  children: [
                    Expanded(child: Stat('48', 'طلب', Icons.receipt_long)),
                    Expanded(child: Stat('2,160', 'مبيعات', Icons.payments)),
                    Expanded(child: Stat('4.8', 'تقييم', Icons.star)),
                  ],
                ),
                // عمودان من الأقسام على الشاشة العريضة، وعمود واحد على الجوال.
                LayoutBuilder(
                  builder: (context, constraints) => constraints.maxWidth < 600
                      ? const Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [popular, hours],
                        )
                      : const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: popular),
                            Expanded(child: hours),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
