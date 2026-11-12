import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/settings.dart';
import 'package:glm/features/assistant/assistant.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> json(String name) => jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Map<String, dynamic>;

/// The assistant's real replies from a local server (its opening, and a guide answer about the slots).
class FakeAssistant implements AssistantRepository {
  final List<String> asked = [];

  @override
  Future<Map<String, dynamic>> start(String page) async => json('assistant_start');
  @override
  Future<Map<String, dynamic>> ask(
    String question, {
    String? topic,
    required String page,
    int? leagueId,
    List<Map<String, String>> history = const [],
  }) async {
    asked.add('$question|$topic|$page|$leagueId');
    return json('assistant_answer');
  }
}

void main() {
  test('the screen and league the assistant is asked from, and where its answer leads', () {
    expect(contextOf('/'), (page: 'home', league: null));
    expect(contextOf('/leagues/8/market'), (page: 'market', league: 8));
    expect(contextOf('/leagues/8'), (page: 'league', league: 8));
    expect(goRoute('leagues', 8), '/leagues');
    expect(goRoute('training', 8), '/leagues/8/training');
    expect(goRoute('wallet', null), '/wallet');
    expect(goRoute(null, 8), isNull);
  });

  testWidgets('its opening, a suggested question asked, and its answer with where to go', (t) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fake = FakeAssistant();
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => const Scaffold())],
    );
    await t.pumpWidget(
      ProviderScope(
        overrides: [preferencesProvider.overrideWithValue(prefs), assistantRepositoryProvider.overrideWithValue(fake)],
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
          home: Scaffold(
            body: AssistantSheet(router: router, path: '/leagues/8/market'),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('المدرب المساعد'), findsOneWidget);
    expect(find.textContaining('أهلاً كوتش'), findsOneWidget);
    await t.tap(find.text('ما هي فتحات المدرب؟'));
    await t.pumpAndSettle();
    expect(fake.asked, ['ما هي فتحات المدرب؟|slots|market|8']);
    expect(find.textContaining('لك 8 فتحات'), findsOneWidget);
    expect(find.text('افتح'), findsOneWidget);
  });
}
