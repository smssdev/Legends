import 'package:go_router/go_router.dart';

import 'auth.dart';
import 'pages.dart';
import 'routes.dart';

GoRouter buildRouter(Auth auth) => GoRouter(
  initialLocation: Routes.menu,
  // أعد تشغيل التحويل كلما تغيّر تسجيل الدخول.
  refreshListenable: auth,
  // يعمل قبل كل انتقال. أعد عنواناً جديداً لترسل الشخص إلى مكان آخر، أو null.
  redirect: (context, state) {
    final path = state.matchedLocation;
    if (!auth.signedIn && path.startsWith(Routes.account)) {
      return Routes.signIn(from: state.uri.toString());
    }
    if (auth.signedIn && path == '/signin') {
      // تذكّر أين أراد الشخص أن يذهب، ولا تُرجع إلا إلى داخل التطبيق.
      final from = state.uri.queryParameters['from'] ?? Routes.menu;
      return from.startsWith('/') && !from.startsWith('//')
          ? from
          : Routes.menu;
    }
    return null;
  },
  // أي عنوان لا يطابق مساراً.
  errorBuilder: (context, state) => NotFoundPage(uri: state.uri),
  routes: [
    // ثلاثة ألسنة، لكل منها كومة صفحاته، تبقى حية حين تنتقل بينها.
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
                // مسار ابن: /menu/latte فوق /menu، فيعود زر الرجوع إلى القائمة.
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
                  // يُسأل قبل مغادرة هذا المسار بأي طريقة: زر الرجوع، أو لسان، أو go.
                  onExit: (context, state) =>
                      EditNamePage.confirmLeave(context),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    // خارج الإطار: تسجيل الدخول يغطي الشاشة كلها، بلا ألسنة.
    GoRoute(
      path: '/signin',
      builder: (context, state) => SignInPage(
        auth: auth,
        from: state.uri.queryParameters['from'] ?? Routes.menu,
      ),
    ),
  ],
);
