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
      home: SpecialPage(api: CafeApi(http.Client())),
    ),
  );
}

class SpecialPage extends StatefulWidget {
  const SpecialPage({super.key, required this.api, this.id = 3});

  final CafeApi api;
  final int id;

  @override
  State<SpecialPage> createState() => _SpecialPageState();
}

class _SpecialPageState extends State<SpecialPage> {
  late final Future<Drink> special = widget.api.drink(widget.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مشروب اليوم')),
      body: Center(
        child: FutureBuilder(
          future: special,
          builder: (context, snapshot) => switch (snapshot) {
            AsyncSnapshot(:final error?) => Text('$error'),
            AsyncSnapshot(:final data?) => Card(
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.network(
                    widget.api.imageUrl(data),
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  ListTile(
                    title: Text(
                      data.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    trailing: Text('${data.price} جنيه'),
                  ),
                ],
              ),
            ),
            _ => const CircularProgressIndicator(),
          },
        ),
      ),
    );
  }
}
