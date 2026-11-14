import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/api/gen/models.g.dart' as api;
import 'package:glm/features/home/first_steps.dart';
import 'package:glm/features/leagues/tabs/office_extras.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/theme.dart';

Future<void> show(WidgetTester t, Widget child) async {
  t.view.physicalSize = const Size(844, 390) * 2;
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: glmTheme(day: false),
      locale: const Locale('ar'),
      supportedLocales: L.supportedLocales,
      localizationsDelegates: const [
        L.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Center(child: SizedBox(width: 360, child: child)),
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets('[Sprint 64 F3] since the last visit: the result, then the position, then the offers, by a tap', (t) async {
    final club = {'id': 1, 'name': 'Liverpool', 'code': 'LIV', 'crest_url': '/c.svg'};
    final since = api.ClubBoardSince.fromJson({
      'matches': 2,
      'last': {
        'match_id': 9,
        'home': club,
        'away': {...club, 'id': 2, 'name': 'Arsenal'},
        'home_goals': 2,
        'away_goals': 0,
        'result': 1,
      },
      'position': {'before': 5, 'now': 3},
      'offers': 2,
    });
    await show(t, SinceVisitCard(since: since));
    expect(find.text('2 - 0'), findsOneWidget);
    await t.tap(find.byType(SinceVisitCard));
    await t.pumpAndSettle();
    expect(find.text('5 → 3'), findsOneWidget);
    expect(find.text('تقدمت 2 مراكز'), findsOneWidget);
    await t.tap(find.byType(SinceVisitCard));
    await t.pumpAndSettle();
    expect(find.text('عروض تنتظر ردك'), findsOneWidget);
  });

  testWidgets('[Sprint 64 F2] three first steps, each done in the game; gone once the three are done', (t) async {
    await show(t, const FirstSteps(steps: {'club': true, 'lineup': false, 'match': false}, leagueId: 8));
    expect(find.text('خطواتك الأولى · 1/3'), findsOneWidget);
    expect(find.text('العب مباراتك الأولى'), findsOneWidget);
    await show(t, const FirstSteps(steps: {'club': true, 'lineup': true, 'match': true}, leagueId: 8));
    expect(find.textContaining('خطواتك الأولى'), findsNothing);
  });
}
