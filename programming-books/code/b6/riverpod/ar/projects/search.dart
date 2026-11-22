import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'features/orders/domain/order.dart';

const names = {'latte': 'لاتيه', 'tea': 'شاي بالنعناع', 'cake': 'كيك الكرز'};

// حالات المجال، بالكلمات: فالمجال بلا نصوص.
const statusNames = {
  OrderStatus.pending: 'معلّق',
  OrderStatus.preparing: 'قيد التحضير',
  OrderStatus.ready: 'جاهز',
  OrderStatus.cancelled: 'ملغى',
};

var searches = <String>[];

// autoDispose: حين لا يشاهد أحد هذا البحث يُرمى.
final searchProvider = FutureProvider.autoDispose.family<List<MenuItem>, String>(
  (ref, query) async {
    var disposed = false;
    ref.onDispose(() => disposed = true);
    // انتظر قليلاً؛ فإن كتب الشخص من جديد يكون هذا البحث قد رُمي، فلا يُنفَّذ.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (disposed) {
      return const [];
    }
    searches.add(query);
    return [
      for (final item in menu)
        if (names[item.id]!.toLowerCase().contains(query.toLowerCase())) item,
    ];
  },
);

final queryProvider = NotifierProvider<QueryNotifier, String>(
  QueryNotifier.new,
);

class QueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String text) => state = text;
}

void main() {
  runApp(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        // من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),

        theme: ThemeData(colorSchemeSeed: Colors.brown),
        home: const SearchPage(),
      ),
    ),
  );
}

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchProvider(ref.watch(queryProvider)));
    return Scaffold(
      appBar: AppBar(title: const Text('ابحث في القائمة')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'ابحث في القائمة',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: ref.read(queryProvider.notifier).set,
            ),
          ),
          Expanded(
            child: switch (results) {
              AsyncValue(:final value?) => ListView(
                children: [
                  for (final item in value)
                    ListTile(
                      title: Text(names[item.id]!),
                      trailing: Text('${item.price.pounds} جنيه'),
                    ),
                ],
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}
