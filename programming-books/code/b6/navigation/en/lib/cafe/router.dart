import 'package:go_router/go_router.dart';

import 'auth.dart';
import 'pages.dart';
import 'routes.dart';

GoRouter buildRouter(Auth auth) => GoRouter(
  initialLocation: Routes.menu,
  // Run the redirect again whenever the auth changes.
  refreshListenable: auth,
  // Runs before every navigation. Return a new address to send the person elsewhere, or null.
  redirect: (context, state) {
    final path = state.matchedLocation;
    if (!auth.signedIn && path.startsWith(Routes.account)) {
      return Routes.signIn(from: state.uri.toString());
    }
    if (auth.signedIn && path == '/signin') {
      // Remember where the person wanted to go, and only ever return inside the app.
      final from = state.uri.queryParameters['from'] ?? Routes.menu;
      return from.startsWith('/') && !from.startsWith('//')
          ? from
          : Routes.menu;
    }
    return null;
  },
  // Any address that matches no route.
  errorBuilder: (context, state) => NotFoundPage(uri: state.uri),
  routes: [
    // Three tabs, each with its own stack of pages, kept alive when you switch.
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => TabsScaffold(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.menu,
              builder: (context, state) => MenuPage(
                max: int.tryParse(state.uri.queryParameters['max'] ?? ''),
              ),
              routes: [
                // A child route: /menu/latte sits on top of /menu, so the back button returns to the menu.
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      DrinkPage(id: state.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.orders,
              builder: (context, state) => const OrdersPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      OrderPage(id: int.tryParse(state.pathParameters['id']!)),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.account,
              builder: (context, state) => AccountPage(auth: auth),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) => const EditNamePage(),
                  // Asked before leaving this route by any way: back button, tab, or go.
                  onExit: (context, state) =>
                      EditNamePage.confirmLeave(context),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    // Outside the shell: sign-in covers the whole screen, without tabs.
    GoRoute(
      path: '/signin',
      builder: (context, state) => SignInPage(
        auth: auth,
        from: state.uri.queryParameters['from'] ?? Routes.menu,
      ),
    ),
  ],
);
