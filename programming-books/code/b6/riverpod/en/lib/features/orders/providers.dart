import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/orders_repository_impl.dart';
import 'data/orders_source.dart';
import 'domain/order.dart';
import 'domain/orders_repository.dart';
import 'domain/place_order.dart';

// The feature's wiring: the only file of the feature that knows the data layer.

// Dependencies are providers too: the app reads them, tests replace them.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
final ordersSourceProvider = Provider<OrdersSource>(
  (ref) => FakeOrdersSource(),
);

// Providers build each other: change the source, and everything above it is rebuilt.
final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => OrdersRepositoryImpl(ref.watch(ordersSourceProvider)),
);
final placeOrderProvider = Provider<PlaceOrder>(
  (ref) => PlaceOrder(
    ref.watch(ordersRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

// Loading, ready or failed: FutureProvider gives the screen an AsyncValue.
final historyProvider = FutureProvider<List<Order>>(
  (ref) => ref.watch(ordersRepositoryProvider).history(),
);
