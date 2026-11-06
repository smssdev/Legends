import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/ui/forgot_screen.dart';
import 'features/auth/ui/login_screen.dart';
import 'features/auth/ui/register_screen.dart';
import 'features/club/lineup_screen.dart';
import 'features/club/squad_screen.dart';
import 'features/club/extras_screens.dart';
import 'features/club/tactics_screen.dart';
import 'features/home/home_screen.dart';
import 'features/leagues/create_league_screen.dart';
import 'features/leagues/join_screen.dart';
import 'features/leagues/league_screen.dart';
import 'features/leagues/my_leagues_screen.dart';
import 'features/leagues/pick_team_screen.dart';
import 'features/health/status_screens.dart';
import 'features/inbox/inbox_screen.dart';
import 'features/market/market_screen.dart';
import 'features/market/scout_screen.dart';
import 'features/match/live_screen.dart';
import 'features/money/finance_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/money/stadium_screen.dart';
import 'features/wallet/wallet_screen.dart';
import 'features/match/report_screen.dart';

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
      // A guest from an invite link signs in first, then lands on the link.
      if (!signedIn) return guest.contains(here) ? null : (here.startsWith('/join') ? '/login?from=${Uri.encodeComponent(state.uri.toString())}' : '/login');
      final from = state.uri.queryParameters['from'];
      if (from != null && guest.contains(here)) return from;
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
      // [Sprint 16] The leagues, and an invite link (gamelegendmanager.online/join/CODE) opening the app on its code.
      GoRoute(path: '/leagues', builder: (_, _) => const MyLeaguesScreen()),
      GoRoute(path: '/leagues/new', builder: (_, _) => const CreateLeagueScreen()),
      GoRoute(path: '/join', builder: (_, s) => JoinScreen(code: s.uri.queryParameters['code'])),
      GoRoute(path: '/join/:code', builder: (_, s) => JoinScreen(code: s.pathParameters['code'])),
      GoRoute(path: '/leagues/:id', builder: (_, s) => LeagueScreen(id: int.parse(s.pathParameters['id']!))),
      // [Sprint 17] My team in the league: the squad, the lineup, the tactics.
      GoRoute(path: '/leagues/:id/squad', builder: (_, s) => SquadScreen(leagueId: int.parse(s.pathParameters['id']!))),
      GoRoute(path: '/leagues/:id/lineup', builder: (_, s) => LineupScreen(leagueId: int.parse(s.pathParameters['id']!))),
      GoRoute(path: '/leagues/:id/tactics', builder: (_, s) => TacticsScreen(leagueId: int.parse(s.pathParameters['id']!))),
      GoRoute(path: '/inbox', builder: (_, _) => const InboxScreen()),
      GoRoute(path: '/leagues/:id/finance', builder: (_, s) => FinanceScreen(leagueId: int.parse(s.pathParameters['id']!))),
      GoRoute(path: '/leagues/:id/stadium', builder: (_, s) => StadiumScreen(leagueId: int.parse(s.pathParameters['id']!))),
      GoRoute(path: '/leagues/:id/market', builder: (_, s) => MarketScreen(leagueId: int.parse(s.pathParameters['id']!))),
      GoRoute(path: '/leagues/:id/scout', builder: (_, s) => ScoutScreen(leagueId: int.parse(s.pathParameters['id']!))),
      GoRoute(path: '/coaches/:id', builder: (_, s) => CoachProfileScreen(userId: int.parse(s.pathParameters['id']!))),
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: '/wallet', builder: (_, _) => const WalletScreen()),
      GoRoute(path: '/leagues/:id/training', builder: (_, s) => TrainingScreen(leagueId: int.parse(s.pathParameters['id']!))),
      GoRoute(path: '/leagues/:id/specialists', builder: (_, s) => SpecialistsScreen(leagueId: int.parse(s.pathParameters['id']!))),
      GoRoute(path: '/leagues/:id/spy', builder: (_, s) => SpyScreen(leagueId: int.parse(s.pathParameters['id']!))),
      GoRoute(path: '/leagues/:id/quests', builder: (_, s) => QuestsScreen(leagueId: int.parse(s.pathParameters['id']!))),
      GoRoute(path: '/leagues/:id/honours', builder: (_, s) => HonoursScreen(leagueId: int.parse(s.pathParameters['id']!))),
      GoRoute(path: '/match/:id', builder: (_, s) => LiveMatchScreen(matchId: int.parse(s.pathParameters['id']!))),
      GoRoute(path: '/match/:id/report', builder: (_, s) => MatchReportScreen(matchId: int.parse(s.pathParameters['id']!), coach: s.uri.queryParameters['coach'] == 'true')),
      GoRoute(path: '/leagues/:id/pick', builder: (_, s) => PickTeamScreen(leagueId: int.parse(s.pathParameters['id']!))),
    ],
  );
});
