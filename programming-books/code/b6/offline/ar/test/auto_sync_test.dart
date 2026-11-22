import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/offline/auto_sync.dart';
import 'package:bit_app/offline/providers.dart';

void main() {
  test('العودة إلى الاتصال ترسل ما كان ينتظر', () async {
    final container = ProviderContainer.test();
    container.listen(autoSyncProvider, (previous, next) {});
    container.read(onlineProvider.notifier).set(false);
    await container.read(ordersActionsProvider).place('Latte');
    expect((await container.read(localProvider).outbox()).length, 1);

    container.read(onlineProvider.notifier).set(true);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect((await container.read(localProvider).outbox()), isEmpty);
    expect(container.read(remoteProvider).orders.length, 1);
  });
}
