import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/ui/forgot_screen.dart';
import 'features/auth/ui/login_screen.dart';
import 'features/auth/ui/register_screen.dart';
import 'features/home/home_screen.dart';
import 'features/health/status_screens.dart';

/// [Sprint 15 F1] The app's pages: the start while the account is checked, then the sign-in pages for a guest and the
/// home for a coach. The router listens to the account and moves by itself on sign-in, sign-out and a refused token.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);
  const guest = {'/login', '/register', '/forgot'};

  return GoRouter(
    initialLocation: '/start',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final here = state.matchedLocation;
      if (auth.isLoading && !auth.hasValue) return here == '/start' ? null : '/start';
      if (auth.hasError && !auth.hasValue) return '/offline';
      final signedIn = auth.value != null;
      if (!signedIn) return guest.contains(here) ? null : '/login';
      return guest.contains(here) || here == '/start' || here == '/offline' ? '/' : null;
    },
    routes: [
      GoRoute(path: '/start', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/offline', builder: (context, _) => Consumer(builder: (context, ref, _) => OfflineScreen(
            message: '${ref.read(authProvider).error}', onRetry: () => ref.invalidate(authProvider)))),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/forgot', builder: (_, _) => const ForgotScreen()),
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    ],
  );
});
