import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'features/orders/presentation/orders_page.dart';
import 'features/orders/providers.dart';
import 'features/orders/data/orders_source.dart';

void main() {
  runApp(
    ProviderScope(
      // One override: a source that always fails.
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 22, 10)),
        ordersSourceProvider.overrideWithValue(FakeOrdersSource(fails: true)),
      ],
      child: const OrdersApp(),
    ),
  );
}
