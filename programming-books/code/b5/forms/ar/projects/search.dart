import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: const SearchPage(),
    ),
  );
}

final drinks = 'لاتيه,كابتشينو,موكا,شاي بالنعناع,شاي أخضر,عصير برتقال,ليموناضة,شوكولاتة ساخنة'
    .split(',');

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final query = TextEditingController();

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = query.text.trim().toLowerCase();
    final found = [
      for (final d in drinks)
        if (d.toLowerCase().contains(words)) d,
    ];
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: query,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'ابحث في القائمة',
            border: InputBorder.none,
            suffixIcon: query.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'امسح',
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(query.clear),
                  ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
      body: found.isEmpty
          ? const Center(child: Text('لا مشروب مطابق'))
          : ListView(
              children: [
                for (final d in found)
                  ListTile(
                    leading: const Icon(Icons.local_cafe),
                    title: Text(d),
                  ),
              ],
            ),
    );
  }
}
