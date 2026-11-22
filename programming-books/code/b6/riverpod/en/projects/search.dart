import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'features/orders/domain/order.dart';

const names = {'latte': 'Latte', 'tea': 'Mint tea', 'cake': 'Cherry cake'};

// The domain's statuses, in words: the domain has no text.
const statusNames = {
  OrderStatus.pending: 'Pending',
  OrderStatus.preparing: 'Preparing',
  OrderStatus.ready: 'Ready',
  OrderStatus.cancelled: 'Cancelled',
};

var searches = <String>[];

// autoDispose: when nobody watches this query any more, it is thrown away.
final searchProvider = FutureProvider.autoDispose
    .family<List<MenuItem>, String>((ref, query) async {
      var disposed = false;
      ref.onDispose(() => disposed = true);
      // Wait a little; if the person typed again, this query was disposed and is not searched.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (disposed) {
        return const [];
      }
      searches.add(query);
      return [
        for (final item in menu)
          if (names[item.id]!.toLowerCase().contains(query.toLowerCase())) item,
      ];
    });

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
      appBar: AppBar(title: const Text('Search the menu')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search the menu',
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
                      trailing: Text('${item.price.pounds} EGP'),
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
