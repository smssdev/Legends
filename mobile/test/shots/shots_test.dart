@Tags(["shots"])
library;

// Screenshots of the app's screens with the real fonts, for design review: flutter test test/shots --update-goldens
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/ui/widgets/pitch_name.dart';
import 'package:glm/core/settings.dart';
import 'package:glm/core/sounds.dart';
import 'package:glm/features/club/club_data.dart';
import 'package:glm/features/club/lineup_screen.dart';
import 'package:glm/features/club/squad_screen.dart';
import 'package:glm/features/club/tactics_screen.dart';
import 'package:glm/features/club/team_data.dart';
import 'package:glm/features/health/intro_screen.dart';
import 'package:glm/features/home/home_data.dart';
import 'package:glm/ui/widgets/motion.dart';
import 'package:glm/features/auth/ui/login_screen.dart';
import 'package:glm/features/home/home_screen.dart';
import 'package:glm/features/leagues/league_screen.dart';
import 'package:glm/features/leagues/leagues_repository.dart';
import 'package:glm/api/gen/models.g.dart' as api;
import 'package:glm/features/leagues/models.dart';
import 'package:glm/features/leagues/shell.dart';
import 'package:glm/features/match/live_screen.dart';
import 'package:glm/features/match/match_data.dart';
import 'package:glm/features/match/report_screen.dart';
import 'package:glm/features/market/market_data.dart';
import 'package:glm/features/market/market_screen.dart';
import 'package:glm/features/money/finance_screen.dart';
import 'package:glm/features/money/money_data.dart';
import 'package:glm/features/wallet/wallet_screen.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/size_class.dart';
import 'package:glm/ui/theme.dart';
import 'package:glm/ui/widgets/brand.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../market_test.dart' show FakeMarket;
import '../match_test.dart' show FakeMatchRepository;
import '../team_test.dart' show FakeTeamRepository;
import '../home_answer.dart';

import 'package:glm/core/disk_images.dart';

import 'package:glm/features/matchday/matchday_data.dart' show nextMatchProvider, pressProvider, integrityProvider;
import 'package:glm/features/matchday/matchday_screen.dart';

import 'package:glm/features/tournaments/tournaments_data.dart' show tournamentsProvider;
import 'package:glm/features/tournaments/tournaments_screen.dart';

Map<String, dynamic> json(String name) => jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Map<String, dynamic>;

Future<void> fonts() async {
  for (final (family, files) in [
    ('Tajawal', ['Tajawal-400', 'Tajawal-500', 'Tajawal-700', 'Tajawal-800']),
    ('BarlowCondensed', ['BarlowCondensed-600', 'BarlowCondensed-700', 'BarlowCondensed-800']),
  ]) {
    final l = FontLoader(family);
    for (final f in files) {
      l.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f.ttf').readAsBytesSync())));
    }
    await l.load();
  }
  final icons = FontLoader('MaterialIcons')
    ..addFont(
      Future.value(
        ByteData.sublistView(
          File('${Platform.environment['FLUTTER_ROOT'] ?? '/opt/sdk/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
              .readAsBytesSync(),
        ),
      ),
    );
  await icons.load();
}

const homeJson = {
  'coach': {
    'name': 'حمزة',
    'coins': 1250,
    'account_no': 48213,
    'record': {'won': 7, 'drawn': 2, 'lost': 1},
    'rating': {
      'points': 420,
      'tier': {'key': 'professional', 'division': 3},
    },
  },
  'slots_open': 3,
  'starter_gift': {'coins': 25, 'claimed': false},
  'slots': [
    {
      'slot': 1,
      'state': 'club',
      'league': {'id': 8, 'name': 'Premier League'},
      'club': {'id': 141, 'name': 'Liverpool', 'code': 'LIV'},
      'position': 2,
      'teams': 20,
      'next': {
        'opponent': {'name': 'Arsenal', 'code': 'ARS'},
        'home': true,
        'scheduled_at': '2026-11-08T19:00:00Z',
      },
    },
    {'slot': 2, 'state': 'free'},
    {'slot': 3, 'state': 'locked', 'opens_at': '2030-01-01T00:00:00Z', 'unlock_coins': 50},
  ],
};

/// [Sprint 60 F8, T2] Every text the screen cut (past its lines, or past its width on one line): what reads «…».
/// The names under the places on the pitch (PitchName) may end in «…» as the approved drafts draw them: left out.
List<String> cutTexts(WidgetTester t) {
  final onPitch = find.descendant(of: find.byType(PitchName), matching: find.byType(RichText)).evaluate().toSet();
  return [
    for (final e in find.byType(RichText).evaluate())
      if (!onPitch.contains(e) && (t.renderObject(find.byWidget(e.widget)) as RenderParagraph).didExceedMaxLines)
        (e.widget as RichText).text.toPlainText(),
  ];
}

/// [Sprint 60 T2] The system's text size the screens are drawn at (1 for the reference shots).
double _scale = 1;
String _lang = 'ar';

/// [Sprint 72 R1] A phone the screens are drawn on besides the reference one: its screen, the notch's inset on either
/// side and the keyboard's height when it is up. Android's commonest landscape height is 360, not the reference's 390.
typedef Device = ({String name, Size size, double left, double right, double keyboard, bool golden});

const devices = <Device>[
  (name: 'small', size: Size(640, 360), left: 0, right: 0, keyboard: 0, golden: false),
  (name: 'a360', size: Size(800, 360), left: 0, right: 0, keyboard: 0, golden: true),
  (name: 'big', size: Size(915, 412), left: 0, right: 0, keyboard: 0, golden: false),
  (name: 'tablet', size: Size(1280, 800), left: 0, right: 0, keyboard: 0, golden: false),
  (name: 'notch-left', size: Size(800, 360), left: 40, right: 0, keyboard: 0, golden: false),
  (name: 'notch-right', size: Size(800, 360), left: 0, right: 40, keyboard: 0, golden: false),
];
const waitsForSprint73 = <String>{};

/// [Sprint 73 D10] The screens built to fill a landscape phone (README section 0): no page scroll on any phone.
const fitScreens = {'home', 'league', 'lineup', 'tactics', 'next-match', 'live'};
const keyboardUp = (name: 'keyboard', size: Size(800, 360), left: 0.0, right: 0.0, keyboard: 200.0, golden: false);
Device? _device;

/// [Sprint 65 F1, F3] Run as a screen reader would read it: every control named and at least 48×48 to the finger.
bool _guides = false;

Future<void> shot(
  WidgetTester t,
  String name,
  Widget screen,
  List<Override> overrides, {
  Size size = const Size(844, 390),
  double h = 800,
  String? tap,
  Duration? at,
  IconData? tapIcon,
  double scroll = 0,
  int? tapField,
  String? thenTap,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  DiskImages.instance = DiskImages.none();
  final d = _device;
  if (d != null) size = d.size;
  t.view.physicalSize = size * 2;
  t.view.devicePixelRatio = 2;
  if (d != null) {
    t.view.padding = FakeViewPadding(left: d.left * 2, right: d.right * 2);
    t.view.viewPadding = FakeViewPadding(left: d.left * 2, right: d.right * 2);
    t.view.viewInsets = FakeViewPadding(bottom: d.keyboard * 2);
  }
  addTearDown(t.view.reset);
  ClubCrest.loadFromNetwork = false;
  await t.runAsync(fonts);
  await t.pumpWidget(
    ProviderScope(
      overrides: [preferencesProvider.overrideWithValue(prefs), ...overrides],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: glmTheme(day: false),
        locale: Locale(_lang),
        supportedLocales: L.supportedLocales,
        localizationsDelegates: const [
          L.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(_scale)),
          // [Sprint 72 R7] As the app's root: a tablet draws everything larger.
          child: GlmScale(child: child!),
        ),
        home: screen,
      ),
    ),
  );
  if (at != null) {
    // A moment of an animation (the opening): its pictures first, then the clock moved to [at].
    for (final e in find.byType(Image).evaluate()) {
      // [Sprint 59 F8] A picture from the network (a store item) is not there in a test: it stays blank, not an error.
      await t.runAsync(() => precacheImage((e.widget as Image).image, e, onError: (_, _) {}));
    }
    for (var ms = 0; ms < at.inMilliseconds; ms += 50) {
      await t.pump(const Duration(milliseconds: 50));
    }
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
    return;
  }
  for (var i = 0; i < 10; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  // Let the images decode (the emblem, the coin) before the picture is taken.
  for (final e in find.byType(Image).evaluate()) {
    // [Sprint 59 F8] A picture from the network (a store item) is not there in a test: it stays blank, not an error.
    await t.runAsync(() => precacheImage((e.widget as Image).image, e, onError: (_, _) {}));
  }
  await t.pump(const Duration(milliseconds: 100));
  if (tap != null || tapIcon != null) {
    await t.tap(tap != null ? find.text(tap).last : find.byIcon(tapIcon!).first);
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }
  if (thenTap != null) {
    await t.tap(find.textContaining(thenTap).last);
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }
  if (tapField != null) {
    // [Sprint 72 R5] A field focused with the keyboard up: it must be whole above the keyboard.
    final field = find.byType(EditableText).at(tapField);
    await t.ensureVisible(field);
    await t.tap(field, warnIfMissed: false);
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    final at = t.getRect(field);
    final top = size.height - (_device?.keyboard ?? 0);
    expect(at.bottom <= top + .5 && at.top >= 0, isTrue, reason: '$name: the field is under the keyboard ($at, keyboard from $top)');
  }
  if (scroll > 0) {
    await t.drag(find.byType(Scrollable).first, Offset(0, -scroll));
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }
  // [Sprint 60 F8] No text cut on any screen (it was «تُفتح مجاناً بعد 1144 يو…» and «وقت مستـ…»).
  expect(cutTexts(t), isEmpty, reason: '$name ($_lang): a text is cut${_scale == 1 ? '' : ' at the text size $_scale'}');
  if (d != null) {
    // [Sprint 72 R3] The dock never scrolls: every section is on the screen, whatever its height.
    for (final e in find.descendant(of: find.byType(ConsoleDock), matching: find.byType(Scrollable)).evaluate()) {
      final at = ((e as StatefulElement).state as ScrollableState).position;
      expect(at.maxScrollExtent, 0, reason: '$name on ${d.name}: the dock scrolls');
    }
    // [Sprint 73 D10] A screen built to fill the screen has no page to scroll: what scrolls is a column of it (under
    // 70% of the width), each inside itself. The squad and the market are lists by nature and scroll whole.
    // On the smallest phone (640 wide) the home falls back to one column, a page by nature.
    if (fitScreens.contains(name) && !(name == 'home' && d.name == 'small')) {
      for (final e in find.byType(Scrollable).evaluate()) {
        final state = (e as StatefulElement).state as ScrollableState;
        final at = state.position;
        if (!at.hasContentDimensions || at.maxScrollExtent <= 1 || axisDirectionToAxis(state.axisDirection) != Axis.vertical) continue;
        final wide = (e.renderObject! as RenderBox).size.width;
        expect(
          wide < d.size.width * .7,
          isTrue,
          reason: '$name on ${d.name}: the page scrolls (${at.maxScrollExtent.round()}px, ${wide.round()} wide)',
        );
      }
    }
    // [Sprint 72 R4] Nothing of the screen under the notch: every text clear of the inset on its side.
    for (final e in find.byType(RichText).evaluate()) {
      final box = e.renderObject! as RenderBox;
      if (!box.hasSize || box.size.isEmpty) continue;
      // Its bounds on the screen, whichever way it is turned (a label standing on its side).
      final at = MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);
      expect(
        at.left >= d.left - .5 && at.right <= d.size.width - d.right + .5,
        isTrue,
        reason: '$name on ${d.name}: «${(e.widget as RichText).text.toPlainText()}» under the notch ($at)',
      );
    }
    if (d.golden && _scale == 1 && _lang == 'ar') {
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/${d.name}/$name.png'));
    }
  } else if (_guides) {
    final reader = t.ensureSemantics();
    await t.pump();
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    reader.dispose();
  } else if (_scale == 1 && _lang == 'ar') {
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
  }
  await t.pumpWidget(const SizedBox());
  // [Sprint 59 F8] The requests still answering when the screen goes (a refused one schedules its error) end here.
  await t.pump(const Duration(seconds: 1));
}

void main() {
  // [Sprint 60 T2] The eight screens compared with the site (T1): each one's reference shot, and again at the phone's
  // text set 30% larger (textScaler 1.3) with no text cut.
  final eight = <String, Future<void> Function(WidgetTester)>{};
  void screen(String name, Future<void> Function(WidgetTester) body) {
    eight[name] = body;
    testWidgets(name, body);
  }

  for (final (name, ms) in [('intro-1', 300), ('intro-2', 1450), ('intro-3', 2300)]) {
    testWidgets(name, (t) async {
      Ambient.on = true;
      GameSounds.enabled = false; // no sound plugin in the tests
      addTearDown(() => Ambient.on = false);
      await shot(t, name, const IntroScreen(), [], at: Duration(milliseconds: ms));
    });
  }
  screen(
    'home',
    (t) => shot(t, 'home', const HomeScreen(), [homeProvider.overrideWith((ref) async => HomeData.fromJson(homeAnswer(homeJson)))]),
  );
  screen(
    'league',
    (t) => shot(t, 'league', const LeagueShell(leagueId: 8, location: '/leagues/8', child: LeagueScreen(id: 8)), [
      leagueProvider.overrideWith((ref, id) async => League.of(api.League.fromJson(json('league')['league']))),
      clubSummaryProvider.overrideWith((ref, id) async => ClubSummary.fromJson(json('summary'))),
    ], h: 1400),
  );
  for (final name in ['league-team', 'league-matches', 'league-more']) {
    testWidgets(
      name,
      (t) => shot(
        t,
        name,
        LeagueShell(
          leagueId: 8,
          location: '/leagues/8?tab=${{'league-team': 'team', 'league-matches': 'matches', 'league-more': 'more'}[name]}',
          child: LeagueScreen(id: 8, tab: {'league-team': 'team', 'league-matches': 'matches', 'league-more': 'more'}[name]),
        ),
        [
          leagueProvider.overrideWith((ref, id) async => League.of(api.League.fromJson(json('league')['league']))),
          clubSummaryProvider.overrideWith((ref, id) async => ClubSummary.fromJson(json('summary'))),
          standingsProvider.overrideWith(
            (ref, id) async => [for (final r in json('standings')['table'] as List<dynamic>) StandingRow.fromJson(r)],
          ),
          fixturesProvider.overrideWith(
            (ref, id) async => [for (final f in json('fixtures')['fixtures'] as List<dynamic>) Fixture.of(api.Fixture.fromJson(f))],
          ),
        ],
      ),
    );
  }
  testWidgets(
    'menu',
    (t) => shot(t, 'menu', const LeagueShell(leagueId: 8, location: '/leagues/8/squad', child: SquadScreen(leagueId: 8)), [
      teamRepositoryProvider.overrideWithValue(FakeTeamRepository()),
      leagueProvider.overrideWith((ref, id) async => League.of(api.League.fromJson(json('league')['league']))),
      clubSummaryProvider.overrideWith((ref, id) async => ClubSummary.fromJson(json('summary'))),
    ], tap: 'الفريق'), // [Sprint 59 F8] The dock's team section opens its pages (the old menu button is gone).
  );
  testWidgets('login', (t) => shot(t, 'login', const LoginScreen(), []));
  screen(
    'squad',
    (t) => shot(t, 'squad', const LeagueShell(leagueId: 8, location: '/leagues/8/squad', child: SquadScreen(leagueId: 8)), [
      teamRepositoryProvider.overrideWithValue(FakeTeamRepository()),
      leagueProvider.overrideWith((ref, id) async => League.of(api.League.fromJson(json('league')['league']))),
      clubSummaryProvider.overrideWith((ref, id) async => ClubSummary.fromJson(json('summary'))),
    ]),
  );
  testWidgets(
    'squad-rows',
    (t) => shot(t, 'squad-rows', const LeagueShell(leagueId: 8, location: '/leagues/8/squad', child: SquadScreen(leagueId: 8)), [
      teamRepositoryProvider.overrideWithValue(FakeTeamRepository()),
      leagueProvider.overrideWith((ref, id) async => League.of(api.League.fromJson(json('league')['league']))),
      clubSummaryProvider.overrideWith((ref, id) async => ClubSummary.fromJson(json('summary'))),
    ], scroll: 300),
  );
  screen(
    'lineup',
    (t) => shot(t, 'lineup', const LeagueShell(leagueId: 8, location: '/leagues/8/lineup', child: LineupScreen(leagueId: 8)), [
      teamRepositoryProvider.overrideWithValue(FakeTeamRepository()),
      leagueProvider.overrideWith((ref, id) async => League.of(api.League.fromJson(json('league')['league']))),
      clubSummaryProvider.overrideWith((ref, id) async => ClubSummary.fromJson(json('summary'))),
    ]),
  );
  screen(
    'tactics',
    (t) => shot(t, 'tactics', const TacticsScreen(leagueId: 8), [
      teamRepositoryProvider.overrideWithValue(FakeTeamRepository()),
      clubSummaryProvider.overrideWith((ref, id) async => ClubSummary.fromJson(json('summary'))),
    ]),
  );
  testWidgets(
    'tactics-lines',
    (t) => shot(t, 'tactics-lines', const TacticsScreen(leagueId: 8), [
      teamRepositoryProvider.overrideWithValue(FakeTeamRepository()),
      clubSummaryProvider.overrideWith((ref, id) async => ClubSummary.fromJson(json('summary'))),
    ], scroll: 495),
  );
  testWidgets(
    'tactics-plan',
    (t) => shot(t, 'tactics-plan', const TacticsScreen(leagueId: 8), [
      teamRepositoryProvider.overrideWithValue(FakeTeamRepository()),
      clubSummaryProvider.overrideWith((ref, id) async => ClubSummary.fromJson(json('summary'))),
    ], scroll: 300),
  );
  testWidgets(
    'market-sell',
    (t) => shot(t, 'market-sell', const MarketScreen(leagueId: 8), [marketRepositoryProvider.overrideWithValue(FakeMarket())], tap: 'بيع'),
  );
  testWidgets(
    'report',
    (t) => shot(t, 'report', const MatchReportScreen(matchId: 77, coach: true), [
      matchRepositoryProvider.overrideWithValue(FakeMatchRepository()),
    ]),
  );
  testWidgets(
    'wallet',
    (t) => shot(t, 'wallet', const WalletScreen(), [
      walletProvider.overrideWith(
        (ref) async => WalletView.fromJson({
          ...json('wallet'),
          'balance': 1250,
          'transactions': [
            {'type': 'starter', 'label': 'هدية البداية', 'amount': 25, 'balance_after': 25, 'at': '2026-11-05T20:00:00Z'},
            {'type': 'friendly', 'label': 'ودية', 'amount': -5, 'balance_after': 20, 'at': '2026-11-05T21:00:00Z'},
          ],
        }),
      ),
      storeProvider.overrideWith((ref) async => StoreItem.shown(json('store'))),
    ]),
  );
  testWidgets(
    'finance',
    (t) => shot(t, 'finance', const FinanceScreen(leagueId: 8), [
      financeProvider.overrideWith((ref, id) async => Finance.fromJson(json('finance'))),
    ]),
  );
  screen('market', (t) => shot(t, 'market', const MarketScreen(leagueId: 8), [marketRepositoryProvider.overrideWithValue(FakeMarket())]));
  testWidgets(
    'market-filters',
    (t) => shot(t, 'market-filters', const MarketScreen(leagueId: 8), [
      marketRepositoryProvider.overrideWithValue(FakeMarket()),
    ], tap: 'الفلاتر'),
  );
  // [Sprint 60 T1] The next match, one of the eight screens compared side by side with the site.
  screen(
    'next-match',
    (t) => shot(t, 'next-match', const MatchdayScreen(leagueId: 8), [
      nextMatchProvider.overrideWith(
        (ref, l) async => api.NextMatch.fromJson({...json('next_match')['match'] as Map<String, dynamic>, 'referee': 'strict'}),
      ),
      pressProvider.overrideWith(
        (ref, k) async => api.PressConference.fromJson({...json('press_2794')['press'] as Map<String, dynamic>, 'open': true}),
      ),
      integrityProvider.overrideWith((ref, l) async => api.IntegrityAnswer.fromJson(json('integrity'))),
    ]),
  );
  // [Sprint 60 F7] A screen with its action in the bar at the foot (it was a floating button in a corner).
  testWidgets(
    'tournaments',
    (t) => shot(t, 'tournaments', const TournamentsScreen(), [
      tournamentsProvider.overrideWith(
        (ref) async => [for (final x in json('tournaments')['tournaments'] as List<dynamic>) api.Tournament.fromJson(x)],
      ),
    ]),
  );
  screen(
    'live',
    (t) => shot(t, 'live', const LiveMatchScreen(matchId: 77), [matchRepositoryProvider.overrideWithValue(FakeMatchRepository())]),
  );
  for (final (name, tab) in [('live-orders', 'الأوامر'), ('live-chat', 'الدردشة')]) {
    testWidgets(
      name,
      (t) =>
          shot(t, name, const LiveMatchScreen(matchId: 77), [matchRepositoryProvider.overrideWithValue(FakeMatchRepository())], tap: tab),
    );
  }
  for (final name in eight.keys) {
    testWidgets('$name at 1.3', (t) async {
      _scale = 1.3;
      addTearDown(() => _scale = 1);
      await eight[name]!(t);
    });
    testWidgets('$name in English', (t) async {
      _lang = 'en';
      addTearDown(() => _lang = 'ar');
      await eight[name]!(t);
    });
    // [Sprint 72 R1] On every phone of the matrix: no overflow, no text cut, the dock whole, nothing under a notch.
    for (final d in devices) {
      // The two screens Sprint 73 lays out anew (D3, D4) wait for it on the phones they do not fit yet.
      if (waitsForSprint73.contains('$name on ${d.name}')) continue;
      testWidgets('$name on ${d.name}', (t) async {
        _device = d;
        addTearDown(() => _device = null);
        await eight[name]!(t);
      });
    }
    // [Sprint 65 F1, F3] Every control with a name a screen reader says, and a 48×48 target (Flutter's own guidelines).
    testWidgets('$name: named controls, 48 targets', (t) async {
      _guides = true;
      addTearDown(() => _guides = false);
      await eight[name]!(t);
    });
  }
  // [Sprint 72 R5] The keyboard up (in landscape it takes more than half the screen): nothing overflows, and the
  // field being typed in stays above it.
  testWidgets('login with the keyboard up', (t) async {
    _device = keyboardUp;
    addTearDown(() => _device = null);
    await shot(t, 'login', const LoginScreen(), [], tapField: 1);
  });
  testWidgets('the match chat with the keyboard up', (t) async {
    _device = keyboardUp;
    addTearDown(() => _device = null);
    await shot(
      t,
      'live-chat',
      const LiveMatchScreen(matchId: 77),
      [matchRepositoryProvider.overrideWithValue(FakeMatchRepository())],
      tap: 'الدردشة',
      thenTap: 'الدردشة ',
      tapField: 0,
    );
  });
}
