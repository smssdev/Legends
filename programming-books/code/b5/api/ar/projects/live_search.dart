import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import 'cafe_api.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: SearchPage(api: CafeApi(http.Client())),
    ),
  );
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.api});

  final CafeApi api;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  Timer? wait;
  List<Drink>? results;
  int asked = 0;

  void changed(String text) {
    // انتظر 400 جزء من الثانية بعد آخر حرف قبل أن تسأل الخادم.
    wait?.cancel();
    wait = Timer(const Duration(milliseconds: 400), () async {
      asked++;
      final found = await widget.api.menu(query: text.trim());
      if (mounted) setState(() => results = found);
    });
  }

  @override
  void dispose() {
    wait?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final found = results;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          onChanged: changed,
          decoration: const InputDecoration(
            hintText: 'ابحث في القائمة',
            border: InputBorder.none,
          ),
        ),
      ),
      body: found == null
          ? const SizedBox()
          : found.isEmpty
          ? const Center(child: Text('لا مشروب مطابق'))
          : ListView(
              children: [
                for (final d in found)
                  ListTile(
                    title: Text(d.name),
                    trailing: Text('${d.price} جنيه'),
                  ),
              ],
            ),
    );
  }
}
