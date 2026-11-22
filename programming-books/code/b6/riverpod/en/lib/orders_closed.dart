import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'features/orders/presentation/orders_page.dart';
import 'features/orders/providers.dart';

void main() {
  runApp(
    ProviderScope(
      // One override: the clock says 23:00.
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 22, 23)),
      ],
      child: const OrdersApp(),
    ),
  );
}
