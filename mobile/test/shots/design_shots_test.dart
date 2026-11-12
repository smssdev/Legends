@Tags(["shots"])
library;

// [Sprint 47] The approved design's screens upright on a phone (390 × 844), for review:
// flutter test test/shots/design_shots_test.dart --tags shots --run-skipped --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/features/auth/ui/login_screen.dart';
import 'package:glm/features/auth/ui/register_screen.dart';
import 'package:glm/features/health/intro_screen.dart';
import 'package:glm/features/home/home_data.dart';
import 'package:glm/features/home/home_screen.dart';
import 'package:glm/features/club/club_data.dart';
import 'package:glm/features/leagues/league_screen.dart';
import 'package:glm/features/leagues/leagues_repository.dart';
import 'package:glm/features/leagues/models.dart';
import 'package:glm/features/leagues/shell.dart';
import 'package:glm/features/sim/sim_screens.dart';

import 'shots_test.dart' show homeJson, json, shot;

const phone = Size(390, 844);
const wide = Size(844, 390);

void main() {
  testWidgets('wide intro', (t) => shot(t, 'wide-intro', const IntroScreen(), []));
  testWidgets('wide login', (t) => shot(t, 'wide-login', const LoginScreen(), []));
  testWidgets(
    'wide home',
    (t) => shot(t, 'wide-home', const HomeScreen(), [homeProvider.overrideWith((ref) async => HomeData.fromJson(homeJson))]),
  );
  testWidgets('phone intro', (t) => shot(t, 'phone-intro', const IntroScreen(), [], size: phone));
  testWidgets('phone login', (t) => shot(t, 'phone-login', const LoginScreen(), [], size: phone));
  const clubs = [
    SimClub(id: 1, name: 'Liverpool', code: 'LIV', league: 'Premier League', strength: 86),
    SimClub(id: 2, name: 'Arsenal', code: 'ARS', league: 'Premier League', strength: 85),
    SimClub(id: 3, name: 'Real Madrid', code: 'RMA', league: 'LaLiga', strength: 88),
    SimClub(id: 4, name: 'Al Ahly', code: 'AHL', league: 'Egyptian Premier League', strength: 74),
  ];
  testWidgets(
    'phone home',
    (t) => shot(t, 'phone-home', const HomeScreen(), [homeProvider.overrideWith((ref) async => HomeData.fromJson(homeJson))], size: phone),
  );
  testWidgets(
    'phone sim',
    (t) => shot(t, 'phone-sim', const SimSetupScreen(), [simClubsProvider.overrideWith((ref, q) async => clubs)], size: phone),
  );
  testWidgets(
    'phone sim friend',
    (t) => shot(
      t,
      'phone-sim-friend',
      const SimSetupScreen(),
      [simClubsProvider.overrideWith((ref, q) async => clubs)],
      size: phone,
      tap: 'ضد صديق',
    ),
  );
  testWidgets('wide sim', (t) => shot(t, 'wide-sim', const SimSetupScreen(), [simClubsProvider.overrideWith((ref, q) async => clubs)]));
  testWidgets(
    'wide versus',
    (t) => shot(t, 'wide-versus', SimVersusScreen(home: clubs[0], away: clubs[1], friend: true, matchUrl: 'x', inviteUrl: 'y'), []),
  );
  testWidgets(
    'wide league',
    (t) => shot(t, 'wide-league', const LeagueShell(leagueId: 8, location: '/leagues/8', child: LeagueScreen(id: 8)), [
      leagueProvider.overrideWith((ref, id) async => League.fromJson(json('league')['league'] as Map<String, dynamic>)),
      clubSummaryProvider.overrideWith((ref, id) async => ClubSummary.fromJson(json('summary'))),
    ]),
  );
  testWidgets(
    'phone versus',
    (t) => shot(
      t,
      'phone-versus',
      SimVersusScreen(home: clubs[0], away: clubs[1], friend: true, matchUrl: 'x', inviteUrl: 'y'),
      [],
      size: phone,
    ),
  );
  testWidgets(
    'phone league',
    (t) => shot(t, 'phone-league', const LeagueShell(leagueId: 8, location: '/leagues/8', child: LeagueScreen(id: 8)), [
      leagueProvider.overrideWith((ref, id) async => League.fromJson(json('league')['league'] as Map<String, dynamic>)),
      clubSummaryProvider.overrideWith((ref, id) async => ClubSummary.fromJson(json('summary'))),
    ], size: phone),
  );
  testWidgets('phone register', (t) => shot(t, 'phone-register', const RegisterScreen(), [], size: phone));
}
