import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),

      theme: ThemeData(colorSchemeSeed: Colors.brown),
      home: const CupsPage(),
    ),
  );
}

class CupsPage extends StatefulWidget {
  const CupsPage({super.key});

  @override
  State<CupsPage> createState() => _CupsPageState();
}

class _CupsPageState extends State<CupsPage> {
  final prefs = SharedPreferencesAsync();
  int? cups;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final saved = await prefs.getInt('cups') ?? 0;
    if (mounted) {
      setState(() => cups = saved);
    }
  }

  Future<void> change(int value) async {
    setState(() => cups = value);
    await prefs.setInt('cups', value);
  }

  @override
  Widget build(BuildContext context) {
    final cups = this.cups;
    return Scaffold(
      appBar: AppBar(title: const Text('أكواب اليوم')),
      // Until the saved number arrives, show nothing rather than a wrong 0.
      body: cups == null
          ? const SizedBox()
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 16,
                children: [
                  Text(
                    '$cups',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  FilledButton.icon(
                    onPressed: () => change(cups + 1),
                    icon: const Icon(Icons.coffee),
                    label: const Text('كوب آخر'),
                  ),
                  TextButton(
                    onPressed: () => change(0),
                    child: const Text('صفّر'),
                  ),
                ],
              ),
            ),
    );
  }
}
