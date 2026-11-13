import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/settings.dart';
import 'package:glm/features/social/social_screens.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/theme.dart';
import 'package:glm/ui/widgets/brand.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glm/core/live/live_channels.dart';

import 'fakes/live_feed.dart';

import 'package:glm/api/gen/models.g.dart' as api;

Map<String, dynamic> json(String name) => jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Map<String, dynamic>;

/// Real replies from a local server (league 8: a friendly played, the round's predictions, a group's message).
class FakeSocial implements SocialRepository {
  final List<String> sent = [];

  @override
  Future<api.Friendlies> friendlies(int league) async => api.Friendlies.fromJson(json('friendlies'));
  @override
  Future<api.Friendly> playFriendly(int league, int opponent) async {
    sent.add('friendly $opponent');
    return api.Friendly.fromJson(json('friendly_played')['friendly']);
  }

  @override
  Future<api.Predictions> predictions(int league) async => api.Predictions.fromJson(json('predictions'));
  @override
  Future<api.Predictions> predict(int league, int fixture, String pick) async {
    sent.add('predict $fixture $pick');
    return api.Predictions.fromJson(json('predictions'));
  }

  @override
  Future<api.Newspaper> newspaper(int league) async => api.Newspaper.fromJson({
    ...json('newspaper'),
    'pending': [
      {
        'id': 3,
        'title': 'Liverpool on top',
        'body': 'A great start for the reds this season.',
        'status': 'pending',
        'author': {'id': 9, 'name': 'Hamza'},
        'at': '2026-11-06T08:00:00Z',
      },
    ],
  });
  @override
  Future<Map<String, dynamic>> write(int league, String title, String body) async => json('newspaper');
  @override
  Future<Map<String, dynamic>> decide(int league, int article, bool publish) async {
    sent.add('article $article $publish');
    return json('newspaper');
  }

  @override
  Future<api.GroupsAnswer> groups() async => api.GroupsAnswer.fromJson(json('groups'));
  int loads = 0;
  @override
  Future<List<api.ChatMessage>> messages(int group) async => [
    if (++loads < 0) api.ChatMessage.fromJson(const <String, dynamic>{}),
    for (final m in json('group_messages')['messages'] as List<dynamic>) api.ChatMessage.fromJson(m),
    api.ChatMessage.fromJson({
      'id': 2,
      'kind': 'audio',
      'deleted': false,
      'body': '',
      'user': {'id': 9, 'name': 'حمزة', 'username': 'hamza'},
      'seconds': 7,
      'reactions': <dynamic>[],
      'created_at': '2026-11-06T08:00:00Z',
    }),
  ];
  @override
  Future<void> say(int group, String body, {int? replyTo}) async => sent.add('say $group $body');
  @override
  Future<void> read(int group) async {}
}

Future<void> pump(WidgetTester t, Widget screen, FakeSocial social, {FakeFeed? feed}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  t.view.physicalSize = const Size(360 * 3, 3000 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  ClubCrest.loadFromNetwork = false;
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        socialRepositoryProvider.overrideWithValue(social),
        liveFeedProvider.overrideWithValue(feed ?? FakeFeed()),
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
  testWidgets('a friendly played, then played back to full time with the best players', (t) async {
    final s = FakeSocial();
    await pump(t, const FriendliesScreen(leagueId: 8), s);
    expect(find.text('الأولى مجانية'), findsOneWidget);
    await t.tap(find.text('العب').first);
    await t.pumpAndSettle();
    expect(s.sent, ['friendly 142']);
    await t.tap(find.text('تخطَّ'));
    await t.pumpAndSettle();
    expect(find.text('2 - 1'), findsOneWidget);
    expect(find.text('الأفضل في المباراة'), findsOneWidget);
    expect(find.text('Mohamed Salah'), findsWidgets);
  });

  testWidgets('a prediction picked, an article published', (t) async {
    final s = FakeSocial();
    await pump(t, const PredictionsScreen(leagueId: 8), s);
    await t.tap(find.text('تعادل').first);
    await t.pumpAndSettle();
    expect(s.sent, ['predict 2794 draw']);

    await pump(t, const NewspaperScreen(leagueId: 8), s);
    expect(find.textContaining('لا عدد بعد'), findsOneWidget);
    await t.tap(find.text('انشر'));
    await t.pumpAndSettle();
    expect(s.sent.last, 'article 3 true');
  });

  testWidgets('the league\'s group: its message, and one written', (t) async {
    final s = FakeSocial();
    await pump(t, const GroupsScreen(), s);
    await t.tap(find.textContaining('Premier League'));
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('أهلاً بالجميع'), findsOneWidget);
    expect(find.byTooltip('أرسل صورة'), findsOneWidget);
    expect(find.byTooltip('سجّل رسالة صوتية'), findsOneWidget);
    expect(find.text('رسالة صوتية 7 ث'), findsOneWidget);
    await t.enterText(find.byType(TextField), 'مباراة قوية الليلة');
    await t.tap(find.byIcon(Icons.send_rounded));
    await t.pump(const Duration(milliseconds: 500));
    expect(s.sent, ['say 8 مباراة قوية الليلة']);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('[Sprint 53] the group on its channel: a message asks at once, and the 4-second poll rests', (t) async {
    final s = FakeSocial();
    final feed = FakeFeed();
    await pump(t, const GroupsScreen(), s, feed: feed);
    await t.tap(find.textContaining('Premier League'));
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(feed.channels, ['chat.8']);
    feed.sub.on = true;
    await t.pump(const Duration(milliseconds: 100));
    final loads = s.loads;
    // On the channel: no poll for the next 20 seconds (it was every 4)...
    await t.pump(const Duration(seconds: 20));
    expect(s.loads, loads);
    // ...and a new message is fetched as soon as it is announced.
    feed.push('chat', {
      'message': {'id': 3},
    });
    await t.pump(const Duration(milliseconds: 100));
    expect(s.loads, loads + 1);
    await t.pumpWidget(const SizedBox());
    expect(feed.sub.left, isTrue);
  });
}
