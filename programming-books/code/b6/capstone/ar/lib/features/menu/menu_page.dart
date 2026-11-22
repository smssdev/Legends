import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../design/tokens.dart';
import '../../state/providers.dart';

// كل ميزة في مجلدها: صفحاتها، ولا شيء من غيرها.
class MenuPage extends ConsumerWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menu = ref.watch(menuProvider);
    final count = ref.watch(cartProvider).values.fold(0, (a, b) => a + b);
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('القائمة'),
        actions: [
          IconButton(
            tooltip: 'افتح طلبك',
            onPressed: () => context.go('/cart'),
            // الشارة تتحرك فقط إن سمح الشخص بالحركة (الفصل 8).
            icon: AnimatedSwitcher(
              duration: reduce
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              child: Badge.count(
                key: ValueKey(count),
                count: count,
                isLabelVisible: count > 0,
                child: const Icon(Icons.local_cafe),
              ),
            ),
          ),
        ],
      ),
      body: switch (menu) {
        AsyncData(value: (final drinks, fresh: _)) => ListView.builder(
          // لا يُبنى إلا ما على الشاشة من صفوف (الفصل 9).
          itemCount: drinks.length,
          itemBuilder: (context, i) {
            final drink = drinks[i];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Space.m,
                vertical: Space.s,
              ),
              title: Text(drink.name),
              subtitle: Text('${drink.about}\n${drink.price} جنيه'),
              isThreeLine: true,
              trailing: IconButton.filled(
                tooltip: 'أضف ${drink.name}',
                onPressed: () => ref.read(cartProvider.notifier).add(drink.id),
                // داخل ListTile يغلب لون أيقونة البلاطة لون الزر: قله صراحة.
                icon: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            );
          },
        ),
        AsyncError() => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: Space.m,
            children: [
              const Text('تعذّر تحميل القائمة.'),
              FilledButton(
                onPressed: () => ref.invalidate(menuProvider),
                child: const Text('حاول مرة أخرى'),
              ),
            ],
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
