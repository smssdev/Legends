import 'package:go_router/go_router.dart';

import 'features/cart/cart_page.dart';
import 'features/menu/menu_page.dart';
import 'features/orders/order_page.dart';

// Three pages, and a route that a notification can open (Chapter 12).
GoRouter cafeRouter() => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MenuPage(),
      routes: [
        GoRoute(path: 'cart', builder: (context, state) => const CartPage()),
        GoRoute(
          path: 'orders/:id',
          builder: (context, state) =>
              OrderPage(id: state.pathParameters['id']!),
        ),
      ],
    ),
  ],
);
