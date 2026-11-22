import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/features/orders/data/orders_source.dart';
import 'package:bit_app/features/orders/domain/order.dart';
import 'package:bit_app/features/orders/providers.dart';

String show(AsyncValue<List<Order>> v) => switch (v) {
  AsyncValue(:final value?) => 'data: ${value.length} orders',
  AsyncValue(:final error?) => 'error: $error, still loading: ${v.isLoading}',
  _ => 'loading',
};

Future<String> historyAfter(ProviderContainer container, Duration wait) async {
  container.listen(historyProvider, (previous, next) {});
  await Future<void>.delayed(wait);
  return show(container.read(historyProvider));
}

void main() {
  test('الـ provider الفاشل يُعاد، ما لم تُطفأ إعادة المحاولة', () async {
    final offline = ordersSourceProvider.overrideWithValue(
      FakeOrdersSource(fails: true),
    );

    final retrying = ProviderContainer.test(overrides: [offline]);
    debugPrint(
      'default:    ${await historyAfter(retrying, const Duration(milliseconds: 600))}',
    );

    final once = ProviderContainer.test(
      overrides: [offline],
      retry: (count, error) => null,
    );
    debugPrint(
      'no retries: ${await historyAfter(once, const Duration(milliseconds: 600))}',
    );
    expect(once.read(historyProvider).isLoading, isFalse);
  });
}
