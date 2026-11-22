import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/features/orders/domain/order.dart';
import 'package:bit_app/features/orders/presentation/basket.dart';

final builds = {'whole basket': 0, 'select isEmpty': 0};

void main() {
  testWidgets('select rebuilds only when the selected value changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              Consumer(
                builder: (context, ref, _) {
                  ref.watch(basketProvider);
                  builds['whole basket'] = builds['whole basket']! + 1;
                  return const SizedBox();
                },
              ),
              Consumer(
                builder: (context, ref, _) {
                  ref.watch(basketProvider.select((b) => b.isEmpty));
                  builds['select isEmpty'] = builds['select isEmpty']! + 1;
                  return const SizedBox();
                },
              ),
            ],
          ),
        ),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Column)),
    );
    for (var i = 0; i < 3; i++) {
      container.read(basketProvider.notifier).add(menu[i]);
      await tester.pump();
    }
    debugPrint('$builds');
    expect(builds, {'whole basket': 4, 'select isEmpty': 2});
  });
}
