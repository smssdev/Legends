import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/settings.dart';
import 'package:glm/features/auth/ui/login_screen.dart';
import 'package:glm/features/home/home_data.dart';
import 'package:glm/features/home/home_screen.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/theme.dart';
import 'package:glm/ui/widgets/brand.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Widget> app(Widget screen, {List overrides = const [], String language = 'ar', bool day = false}) async {
  SharedPreferences.setMockInitialValues({'glm.language': language});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [preferencesProvider.overrideWithValue(prefs), ...overrides],
    child: MaterialApp(
      theme: glmTheme(day: day),
      locale: Locale(language),
      supportedLocales: L.supportedLocales,
      localizationsDelegates: const [L.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      home: screen,
    ),
  );
}

const homeJson = {
  'coach': {'name': 'حمزة', 'coins': 1250, 'account_no': 48213, 'record': {'won': 7, 'drawn': 2, 'lost': 1},
    'rating': {'points': 420, 'tier': {'key': 'professional', 'division': 3}}},
  'slots_open': 2,
  'slots': [
    {'slot': 1, 'state': 'club', 'pending': 2, 'league': {'id': 5, 'name': 'دوري الأصدقاء', 'status': 'running'},
      'club': {'id': 9, 'name': 'Liverpool', 'crest_url': null, 'cash': 1}, 'position': 2, 'teams': 20,
      'next_match': {'opponent': 'Arsenal', 'venue': 'home', 'live': false, 'scheduled_at': '2030-01-01T19:00:00Z'}},
    {'slot': 2, 'state': 'free'},
    {'slot': 3, 'state': 'locked', 'opens_at': '2030-01-01T00:00:00Z', 'unlock_coins': 50},
  ],
};

void main() {
  setUpAll(() => ClubCrest.loadFromNetwork = false);
  testWidgets('the sign-in is in Arabic, right to left, and asks for both fields', (t) async {
    await t.binding.setSurfaceSize(const Size(420, 1000));
    await t.pumpWidget(await app(const LoginScreen()));
    await t.pumpAndSettle();
    expect(find.text('أهلاً بعودتك'), findsOneWidget);
    expect(Directionality.of(t.element(find.text('أهلاً بعودتك'))), TextDirection.rtl);
    await t.ensureVisible(find.text('دخول').last);
    await t.tap(find.text('دخول').last);
    await t.pump();
    expect(find.text('مطلوب'), findsNWidgets(2));
  });

  testWidgets('the sign-in in English, by day', (t) async {
    await t.pumpWidget(await app(const LoginScreen(), language: 'en', day: true));
    await t.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(Directionality.of(t.element(find.text('Welcome back'))), TextDirection.ltr);
  });

  testWidgets('the home: the coach, his rating, and each kind of slot', (t) async {
    await t.binding.setSurfaceSize(const Size(420, 1600));
    await t.pumpWidget(await app(const HomeScreen(), overrides: [homeProvider.overrideWith((ref) async => HomeData.fromJson(homeJson))]));
    await t.pumpAndSettle();
    expect(find.text('حمزة'), findsOneWidget);
    expect(find.text('1250'), findsOneWidget);
    expect(find.textContaining('المحترف III · 420'), findsOneWidget);
    expect(find.text('Liverpool'), findsOneWidget);
    expect(find.text('/20'), findsOneWidget); // the position badge
    expect(find.text('2'), findsWidgets); // the waiting badge and the slot number
    expect(find.text('فتحة فارغة'), findsOneWidget);
    expect(find.text('أنشئ دورياً'), findsOneWidget);
    expect(find.text('مقفلة'), findsOneWidget);
    expect(find.textContaining('تُفتح مجاناً بعد'), findsOneWidget);
    expect(find.text('افتحها الآن (50 كوينز)'), findsOneWidget);
  });
}
