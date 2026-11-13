import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/settings.dart';
import 'package:glm/features/account/account_data.dart';
import 'package:glm/features/account/profile_screen.dart';
import 'package:glm/features/coach/ranking_screen.dart';
import 'package:glm/features/stats/stats_screen.dart';
import 'package:glm/features/ideas/ideas_screen.dart';
import 'package:glm/features/support/support_screen.dart';
import 'package:glm/features/support/announcements_screen.dart';
import 'package:glm/features/guide/guide_screen.dart';
import 'package:glm/features/inbox/inbox_data.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glm/api/gen/models.g.dart' as api;

Map<String, dynamic> json(String name) => jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Map<String, dynamic>;

/// Real replies from a local server (an account, league 8's stats, the guide), with a poll and a card in their shape.
Future<void> pump(WidgetTester t, Widget screen) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  t.view.physicalSize = const Size(360 * 3, 2400 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        meProvider.overrideWith((ref) async => api.Account.fromJson(json('auth_me')['user'])),
        achievementsProvider.overrideWith((ref) async => api.HomeAchievementsAnswer.fromJson(json('home_achievements')).achievements),
        statsProvider.overrideWith(
          (ref, l) async => api.LeagueStats.fromJson({
            ...json('stats'),
            'scorers': [
              {
                'player': {'id': 1, 'name': 'Mohamed Salah'},
                'club': {'id': 141, 'code': 'LIV', 'name': 'Liverpool', 'crest_url': '/crests/1.svg'},
                'goals': 7,
                'assists': 2,
              },
            ],
          }),
        ),
        ideasProvider.overrideWith(
          (ref) async => api.IdeasAnswer.fromJson({
            ...json('ideas'),
            'polls': [
              {
                'id': 1,
                'question': 'Which mode next?',
                'body': null,
                'state': 'open',
                'options': [
                  {'id': 1, 'label': 'Cups', 'votes': null},
                  {'id': 2, 'label': 'Leagues', 'votes': null},
                ],
                'my_vote': null,
                'starts_at': '2026-11-10T10:00:00Z',
                'ends_at': '2026-11-20T10:00:00Z',
                'total': null,
                'winners': <int>[],
              },
            ],
          }),
        ),
        supportProvider.overrideWith(
          (ref) async => [
            for (final m in [
              {'id': 1, 'body': 'Hello team', 'from_team': false, 'read': true, 'at': '2026-11-06T08:00:00Z'},
              {'id': 2, 'body': 'Welcome!', 'from_team': true, 'read': true, 'at': '2026-11-06T08:05:00Z'},
            ])
              api.SupportMessage.fromJson(m),
          ],
        ),
        announcementsProvider.overrideWith(
          (ref) async => [
            api.AnnouncementCard.fromJson({
              'id': 1,
              'title': 'Season two',
              'body': 'Starts on Friday.',
              'image_url': null,
              'cta': null,
              'sent': 1,
              'at': '2026-11-06T08:00:00Z',
            }),
          ],
        ),
        guideProvider.overrideWith((ref) async => api.GuideAnswer.fromJson(json('guide')).sections),
        rankingProvider.overrideWith((ref) async => api.RankingsCoachesAnswer.fromJson(json('ranking')).coaches),
      ],
      child: MaterialApp(
        theme: glmTheme(day: false),
        locale: const Locale('ar'),
        supportedLocales: L.supportedLocales,
        localizationsDelegates: const [
          L.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: screen,
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  test('an account page opens itself from any message', () {
    expect(appRoute('/ideas', 8), '/ideas');
    expect(appRoute('/stats', 8), '/leagues/8/stats');
  });

  testWidgets('my account: the name, the look, the invite and the badges', (t) async {
    await pump(t, const ProfileScreen());
    expect(find.text('مدرب'), findsOneWidget);
    expect(find.text('C1'), findsOneWidget);
    expect(find.text('ادعُ أصدقاءك'), findsOneWidget);
    expect(find.text('أول فوز'), findsOneWidget);
    expect(find.text('100 مباراة'), findsOneWidget);
    expect(find.text('وثّق حسابك واحصل على 1000 كوينز'), findsOneWidget);
    expect(find.text('إجازة طويلة للحساب كله'), findsOneWidget);
    expect(find.text('احذف حسابي'), findsOneWidget);
    expect(find.text('غيّر الصورة'), findsOneWidget);
  });

  testWidgets('the stats, the ideas, support, the announcements and the guide', (t) async {
    await pump(t, const StatsScreen(leagueId: 8));
    expect(find.text('Mohamed Salah'), findsOneWidget);
    await pump(t, const IdeasScreen());
    expect(find.text('Which mode next?'), findsOneWidget);
    await pump(t, const SupportScreen());
    expect(find.text('فريق اللعبة'), findsOneWidget);
    await pump(t, const AnnouncementsScreen());
    expect(find.text('Season two'), findsOneWidget);
    await pump(t, const RankingScreen());
    expect(find.text('مدرب التجربة'), findsWidgets);
    await pump(t, const GuideScreen());
    expect(find.text('البداية والحساب'), findsOneWidget);
    await t.tap(find.text('البداية والحساب'));
    await t.pumpAndSettle();
    expect(find.text('ما هي فتحات المدرب؟'), findsOneWidget);
  });
}
