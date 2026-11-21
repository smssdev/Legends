import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: const HelloPage(),
    ),
  );
}

class HelloPage extends StatefulWidget {
  const HelloPage({super.key});

  @override
  State<HelloPage> createState() => _HelloPageState();
}

class _HelloPageState extends State<HelloPage> {
  // المتحكم يحمل نص المربع، ويستطيع قراءته أو تغييره.
  final name = TextEditingController();

  @override
  void dispose() {
    // يجب تحرير المتحكمات حين تُزال الصفحة.
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final who = name.text.isEmpty ? 'يا ضيفنا' : name.text;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 24,
          children: [
            TextField(
              controller: name,
              decoration: InputDecoration(
                labelText: 'اسمك',
                hintText: 'كما يُكتب على كوبك',
                prefixIcon: const Icon(Icons.person),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'امسح',
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(name.clear),
                ),
              ),
              // onChanged تعمل مع كل حرف: أعد البناء، فتتبعه التحية.
              onChanged: (_) => setState(() {}),
            ),
            Text(
              'أهلاً $who!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}
