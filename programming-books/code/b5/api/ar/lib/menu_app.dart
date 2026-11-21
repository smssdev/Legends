import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'cafe_api.dart';

void main() => runApp(CafeApp(api: CafeApi(http.Client())));

class CafeApp extends StatelessWidget {
  const CafeApp({super.key, required this.api});

  final CafeApi api;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MenuModel(api)..load(),
      child: MaterialApp(
        // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        debugShowCheckedModeBanner: false,
        home: const MenuPage(),
      ),
    );
  }
}

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  Future<void> order(BuildContext context, Drink drink) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final total = await context.read<MenuModel>().api.order('Bit', [
        drink.id,
      ]);
      messenger.showSnackBar(
        SnackBar(content: Text('أُرسل الطلب: ${drink.name}، $total جنيه')),
      );
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<MenuModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('القائمة')),
      body: switch (model.status) {
        Status.loading => const Center(child: CircularProgressIndicator()),
        Status.failed => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              const Icon(Icons.cloud_off, size: 64),
              const Text('تعذّر تحميل القائمة'),
              Text(model.error ?? ''),
              FilledButton(
                onPressed: model.load,
                child: const Text('أعد المحاولة'),
              ),
            ],
          ),
        ),
        // اسحب إلى الأسفل لتحمّل من جديد.
        Status.ready => RefreshIndicator(
          onRefresh: model.load,
          child: ListView(
            children: [
              for (final drink in model.drinks)
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(model.api.imageUrl(drink)),
                    // الصورة التي يفشل تحميلها تترك الدائرة فارغة، لا خطأ.
                    onBackgroundImageError: (error, stack) {},
                  ),
                  title: Text(drink.name),
                  subtitle: Text('${drink.price} جنيه'),
                  trailing: IconButton(
                    tooltip: 'اطلب ${drink.name}',
                    icon: const Icon(Icons.add_shopping_cart),
                    onPressed: () => order(context, drink),
                  ),
                ),
            ],
          ),
        ),
      },
    );
  }
}
