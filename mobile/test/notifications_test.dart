import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/api/gen/models.g.dart' as api;
import 'package:glm/core/settings.dart';
import 'package:glm/features/inbox/inbox_data.dart';
import 'package:glm/features/notifications/notifications_screen.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('a push opens its screen: the site\'s path inside its league', () {
    expect(appRoute('/stadium', 8), '/leagues/8/stadium');
    expect(appRoute('/transfers', 8), '/leagues/8/market');
    expect(appRoute('/match', 8), '/leagues/8/matchday');
    expect(appRoute('/live/77', null), '/match/77');
    expect(appRoute('/leagues', null), isNull);
  });

  testWidgets('the settings: each kind by its name, and the app\'s pushes not on yet on this server', (t) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = api.NotificationSettings.fromJson(jsonDecode(File('test/fixtures/notifications.json').readAsStringSync()));
    await t.pumpWidget(
      ProviderScope(
        overrides: [preferencesProvider.overrideWithValue(prefs), notificationSettingsProvider.overrideWith((ref) async => settings)],
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
          home: const NotificationsScreen(),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.textContaining('لم تُفعَّل في الخادم بعد'), findsOneWidget);
    expect(find.text('العروض والبيع والإعارة'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNWidgets(8));
  });
}
