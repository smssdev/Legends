import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'features/orders/data/orders_repository_impl.dart';
import 'features/orders/data/orders_source.dart';
import 'features/orders/domain/place_order.dart';
import 'features/orders/presentation/orders_controller.dart';
import 'features/orders/presentation/orders_page.dart';

// The composition root: the only place that knows every concrete class.
void main() {
  final repository = OrdersRepositoryImpl(FakeOrdersSource());
  final placeOrder = PlaceOrder(
    repository,
    clock: () => DateTime(2026, 11, 22, 10),
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => OrdersController(placeOrder, repository),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,

        theme: ThemeData(colorSchemeSeed: Colors.brown),
        home: const OrdersPage(),
      ),
    ),
  );
}
