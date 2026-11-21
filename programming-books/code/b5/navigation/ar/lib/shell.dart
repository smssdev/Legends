import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: const Shell(),
    ),
  );
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int page = 0;

  static const titles = ['القائمة', 'الطلبات', 'حسابي'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titles[page])),
      // القائمة الجانبية تنزلق من حافة البداية.
      drawer: Drawer(
        child: ListView(
          children: const [
            DrawerHeader(
              child: Align(
                alignment: AlignmentDirectional.bottomStart,
                child: Text('مسجّل باسم سارة'),
              ),
            ),
            ListTile(leading: Icon(Icons.settings), title: Text('الإعدادات')),
            ListTile(
              leading: Icon(Icons.help_outline),
              title: Text('المساعدة'),
            ),
          ],
        ),
      ),
      // IndexedStack تُبقي كل الصفحات حية، فتحتفظ كل منها بتمريرها وحالتها.
      body: IndexedStack(
        index: page,
        children: const [
          Center(child: Icon(Icons.local_cafe, size: 96)),
          Center(child: Text('لا طلبات بعد')),
          Center(child: Icon(Icons.person, size: 96)),
        ],
      ),
      // الشريط في الأسفل يختار الصفحة التي يعرضها المحتوى.
      bottomNavigationBar: NavigationBar(
        selectedIndex: page,
        onDestinationSelected: (i) => setState(() => page = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.local_cafe), label: 'القائمة'),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'الطلبات',
          ),
          NavigationDestination(icon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }
}
