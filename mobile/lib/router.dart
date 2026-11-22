import 'package:flutter/material.dart';

import 'features/sim/first_match_screen.dart';
import 'features/sim/first_match_controller.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/account/profile_screen.dart';
import 'features/coach/ranking_screen.dart';
import 'features/stats/stats_screen.dart';
import 'features/ideas/ideas_screen.dart';
import 'features/support/support_screen.dart';
import 'features/support/announcements_screen.dart';
import 'features/guide/guide_screen.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/ui/forgot_screen.dart';
import 'features/auth/ui/login_screen.dart';
import 'features/auth/ui/register_screen.dart';
import 'features/club/lineup_screen.dart';
import 'features/matchday/matchday_screen.dart';
import 'features/matchday/contracts_screen.dart';
import 'features/matchday/tickets_screen.dart';
import 'features/matchday/missed_screen.dart';
import 'features/club/squad_screen.dart';
import 'features/club/takers_screen.dart';
import 'features/club/training_screen.dart';
import 'features/club/specialists_screen.dart';
import 'features/club/spy_screen.dart';
import 'features/club/quests_screen.dart';
import 'features/club/honours_screen.dart';
import 'features/coach/coach_profile_screen.dart';
import 'features/club/tactics_screen.dart';
import 'features/home/home_screen.dart';
import 'features/leagues/create_league_screen.dart';
import 'features/leagues/join_screen.dart';
import 'features/leagues/league_screen.dart';
import 'features/leagues/shell.dart';
import 'features/leagues/my_leagues_screen.dart';
import 'features/leagues/pick_team_screen.dart';
import 'features/health/intro_screen.dart';
import 'features/health/status_screens.dart';
import 'features/inbox/inbox_screen.dart';
import 'features/market/market_screen.dart';
import 'features/market/scout_screen.dart';
import 'features/match/live_screen.dart';
import 'features/money/finance_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/sim/sim_setup_screen.dart';
import 'features/match/sim_source.dart';
import 'features/friendlies/friendlies_screen.dart';
import 'features/predictions/predictions_screen.dart';
import 'features/newspaper/newspaper_screen.dart';
import 'features/groups/groups_screen.dart';
import 'features/tournaments/tournaments_screen.dart';
import 'features/tournaments/new_tournament_screen.dart';
import 'features/tournaments/tournament_screen.dart';
import 'features/tournaments/draw_screen.dart';
import 'features/tournaments/alliance_screen.dart';
import 'features/money/stadium_screen.dart';
import 'features/wallet/wallet_screen.dart';
import 'features/match/report_screen.dart';

/// [Sprint 15 F1] The app's pages: the start while the account is checked, then the sign-in pages for a guest and the
/// home for a coach. The router listens to the account and moves by itself on sign-in, sign-out and a refused token.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authProvider, (_, _) => refresh.value++);
  ref.listen(introDoneProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);
  const guest = {'/login', '/register', '/forgot'};

  return GoRouter(
    initialLocation: '/start',
    refreshListenable: refresh,
    // [2026-11-09] A link to no page: say so, never the red screen.
    errorBuilder: (_, _) => const NotFoundScreen(),
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final here = state.matchedLocation;
      if (auth.isLoading && !auth.hasValue) return here == '/start' ? null : '/start';
      if (auth.hasError && !auth.hasValue) return '/offline';
      // [2026-11-06] The opening plays to its end (or a tap) before the game; a link that arrives meanwhile wins.
      if (here == '/start' && !ref.read(introDoneProvider)) return null;
      final signedIn = auth.value != null;
      // A guest from an invite link signs in first, then lands on the link.
      if (!signedIn) {
        return guest.contains(here)
            ? null
            : (here.startsWith('/join') ? '/login?from=${Uri.encodeComponent(state.uri.toString())}' : '/login');
      }
      final from = state.uri.queryParameters['from'];
      if (from != null && guest.contains(here)) return from;
      // [Sprint 64 F1] A new account plays its first match before the home screen.
      if (guest.contains(here) && ref.read(firstMatchWantedProvider)) return '/first-match';
      return guest.contains(here) || here == '/start' || here == '/offline' ? '/' : null;
    },
    routes: [
      GoRoute(path: '/start', builder: (_, _) => const IntroScreen()),
      GoRoute(
        path: '/offline',
        builder: (context, _) => Consumer(
          builder: (context, ref, _) =>
              OfflineScreen(message: '${ref.read(authProvider).error}', onRetry: () => ref.invalidate(authProvider)),
        ),
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/forgot', builder: (_, _) => const ForgotScreen()),
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      // [Sprint 16] The leagues, and an invite link (gamelegendmanager.online/join/CODE) opening the app on its code.
      GoRoute(path: '/leagues', builder: (_, _) => const MyLeaguesScreen()),
      GoRoute(path: '/leagues/new', builder: (_, _) => const CreateLeagueScreen()),
      GoRoute(
        path: '/join',
        builder: (_, s) => JoinScreen(code: s.uri.queryParameters['code']),
      ),
      GoRoute(
        path: '/join/:code',
        builder: (_, s) => JoinScreen(code: s.pathParameters['code']),
      ),
      // [Sprint 45 M1] A league's screens inside its menu (shell.dart): one tap from any to any, on a wide screen.
      ShellRoute(
        builder: (_, s, child) =>
            LeagueShell(leagueId: int.tryParse(s.pathParameters['id'] ?? '') ?? 0, location: s.uri.toString(), child: child),
        routes: [
          GoRoute(
            path: '/leagues/:id',
            builder: (_, s) => _withId(s, (id) => LeagueScreen(id: id, tab: s.uri.queryParameters['tab'])),
          ),
          GoRoute(
            path: '/leagues/:id/squad',
            builder: (_, s) => _withId(s, (id) => SquadScreen(leagueId: id, clubId: int.tryParse(s.uri.queryParameters['club'] ?? ''))),
          ),
          GoRoute(
            path: '/leagues/:id/lineup',
            builder: (_, s) => _withId(s, (id) => LineupScreen(leagueId: id)),
          ),
          GoRoute(
            path: '/leagues/:id/tactics',
            builder: (_, s) => _withId(s, (id) => TacticsScreen(leagueId: id)),
          ),
          GoRoute(
            path: '/leagues/:id/finance',
            builder: (_, s) => _withId(s, (id) => FinanceScreen(leagueId: id)),
          ),
          GoRoute(
            path: '/leagues/:id/stadium',
            builder: (_, s) => _withId(s, (id) => StadiumScreen(leagueId: id)),
          ),
          GoRoute(
            path: '/leagues/:id/market',
            builder: (_, s) => _withId(s, (id) => MarketScreen(leagueId: id)),
          ),
          GoRoute(
            path: '/leagues/:id/scout',
            builder: (_, s) => _withId(s, (id) => ScoutScreen(leagueId: id)),
          ),
          GoRoute(
            path: '/leagues/:id/alliance',
            builder: (_, s) => _withId(s, (id) => AllianceScreen(leagueId: id)),
          ),
          GoRoute(
            path: '/leagues/:id/friendlies',
            builder: (_, s) => _withId(s, (id) => FriendliesScreen(leagueId: id)),
          ),
          GoRoute(
            path: '/leagues/:id/predictions',
            builder: (_, s) => _withId(s, (id) => PredictionsScreen(leagueId: id)),
          ),
          GoRoute(
            path: '/leagues/:id/newspaper',
            builder: (_, s) => _withId(s, (id) => NewspaperScreen(leagueId: id)),
          ),
          GoRoute(
            path: '/leagues/:id/stats',
            builder: (_, s) => _withId(s, (id) => StatsScreen(leagueId: id)),
          ),
          GoRoute(
            path: '/leagues/:id/missed',
            builder: (_, s) => _withId(s, (id) => MissedScreen(leagueId: id)),
          ),
          GoRoute(
            path: '/leagues/:id/matchday',
            builder: (_, s) => _withId(s, (id) => MatchdayScreen(leagueId: id)),
          ),
          GoRoute(
            path: '/leagues/:id/contracts',
            builder: (_, s) => _withId(s, (id) => ContractsScreen(leagueId: id)),
          ),
          GoRoute(
            path: '/leagues/:id/tickets',
            builder: (_, s) => _withId(s, (id) => TicketsScreen(leagueId: id)),
          ),
          GoRoute(
            path: '/leagues/:id/training',
            builder: (_, s) => _withId(s, (id) => TrainingScreen(leagueId: id)),
          ),
          GoRoute(
            path: '/leagues/:id/takers',
            builder: (_, s) => _withId(s, (id) => TakersScreen(leagueId: id)),
          ),
          GoRoute(
            path: '/leagues/:id/specialists',
            builder: (_, s) => _withId(s, (id) => SpecialistsScreen(leagueId: id)),
          ),
          GoRoute(
            path: '/leagues/:id/spy',
            builder: (_, s) => _withId(s, (id) => SpyScreen(leagueId: id)),
          ),
          GoRoute(
            path: '/leagues/:id/quests',
            builder: (_, s) => _withId(s, (id) => QuestsScreen(leagueId: id)),
          ),
          GoRoute(
            path: '/leagues/:id/honours',
            builder: (_, s) => _withId(s, (id) => HonoursScreen(leagueId: id)),
          ),
        ],
      ),
      GoRoute(path: '/inbox', builder: (_, _) => const InboxScreen()),
      GoRoute(
        path: '/coaches/:id',
        builder: (_, s) => _withId(s, (id) => CoachProfileScreen(userId: id)),
      ),
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: '/groups', builder: (_, _) => const GroupsScreen()),
      GoRoute(
        path: '/groups/join/:code',
        builder: (_, s) => GroupsScreen(joinCode: s.pathParameters['code']),
      ),
      GoRoute(path: '/tournaments', builder: (_, _) => const TournamentsScreen()),
      GoRoute(path: '/tournaments/new', builder: (_, _) => const NewTournamentScreen()),
      GoRoute(
        path: '/tournaments/:id',
        builder: (_, s) => _withId(s, (id) => TournamentScreen(id: id)),
      ),
      GoRoute(
        path: '/tournaments/:id/draw',
        builder: (_, s) => _withId(s, (id) => DrawScreen(id: id)),
      ),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(path: '/ranking', builder: (_, _) => const RankingScreen()),
      GoRoute(path: '/ideas', builder: (_, _) => const IdeasScreen()),
      GoRoute(path: '/support', builder: (_, _) => const SupportScreen()),
      GoRoute(path: '/announcements', builder: (_, _) => const AnnouncementsScreen()),
      GoRoute(path: '/guide', builder: (_, _) => const GuideScreen()),
      GoRoute(path: '/wallet', builder: (_, _) => const WalletScreen()),
      // [Sprint 47] The simulator: a trial match against the computer or a friend.
      GoRoute(path: '/sim', builder: (_, _) => const SimSetupScreen()),
      // [Sprint 64 F1] The new coach's first match.
      GoRoute(path: '/first-match', builder: (_, _) => const FirstMatchScreen()),
      // [Sprint 61 F10] A simulator match played in the app (the live match screen), its seat for a match with a friend.
      GoRoute(
        path: '/sim/match/:id',
        builder: (_, s) => LiveMatchScreen(matchId: SimMatches.handle(s.pathParameters['id']!, s.uri.queryParameters['seat'])),
      ),
      GoRoute(
        path: '/match/:id',
        builder: (_, s) => _withId(s, (id) => LiveMatchScreen(matchId: id)),
      ),
      GoRoute(
        path: '/match/:id/report',
        builder: (_, s) => _withId(s, (id) => MatchReportScreen(matchId: id, coach: s.uri.queryParameters['coach'] == 'true')),
      ),
      GoRoute(
        path: '/leagues/:id/pick',
        builder: (_, s) => _withId(s, (id) => PickTeamScreen(leagueId: id)),
      ),
    ],
  );
});

/// [2026-11-09] A page by its number: a link with a wrong one (/leagues/abc from a notification) shows "not found"
/// instead of a FormatException.
Widget _withId(GoRouterState s, Widget Function(int id) page) {
  final id = int.tryParse(s.pathParameters['id'] ?? '');
  return id == null || id <= 0 ? const NotFoundScreen() : page(id);
}

/// [Sprint 59 F11] Whether a route from outside (a push, an inbox message) is one of the app's own pages: an app path
/// (one slash, no scheme or host) that the router's own table matches. Anything else is not opened.
bool knownRoute(GoRouter router, String? route) {
  if (route == null || !route.startsWith('/') || route.startsWith('//')) return false;
  final uri = Uri.tryParse(route);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return false;
  return router.configuration.findMatch(uri).isNotEmpty;
}
