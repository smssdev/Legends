import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'features/orders/presentation/orders_page.dart';
import 'features/orders/providers.dart';

void main() {
  runApp(
    ProviderScope(
      // مثبتة على 10:00 لصور الكتاب؛ والتطبيق الحقيقي يُبقي DateTime.now.
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 22, 10)),
      ],
      child: const OrdersApp(),
    ),
  );
}
