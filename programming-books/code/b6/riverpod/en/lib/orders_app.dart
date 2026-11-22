import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'features/orders/presentation/orders_page.dart';
import 'features/orders/providers.dart';

void main() {
  runApp(
    ProviderScope(
      // Fixed at 10:00 for the book's screenshots; a real app keeps DateTime.now.
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 22, 10)),
      ],
      child: const OrdersApp(),
    ),
  );
}
