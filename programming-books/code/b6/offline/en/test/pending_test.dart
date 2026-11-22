import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/offline/order.dart';
import 'package:bit_app/offline/pending.dart';
import 'package:bit_app/offline/providers.dart';

void main() {
  test('the badge counts what is waiting', () async {
    final container = ProviderContainer.test();
    container.listen(pendingProvider, (previous, next) {});
    container.read(onlineProvider.notifier).set(false);
    await container.read(ordersActionsProvider).place('Latte');
    await container.read(ordersActionsProvider).place('Cherry cake');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(container.read(pendingProvider), 2);

    container.read(onlineProvider.notifier).set(true);
    await container.read(lastSyncProvider.notifier).run();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(container.read(pendingProvider), 0);
    expect(
      (await container.read(localProvider).all()).every(
        (o) => o.sync == SyncState.synced,
      ),
      isTrue,
    );
  });
}
