import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/api/api_error.dart';
import 'package:glm/features/sim/sim_screens.dart';

import 'screens_test.dart' show app;

/// [Sprint 47] The simulator in the app: the two modes, the teams from the server, the gold button, the face-off.
void main() {
  const clubs = [SimClub(id: 1, name: 'Liverpool', code: 'LIV', strength: 86), SimClub(id: 2, name: 'Arsenal', code: 'ARS', strength: 85)];

  testWidgets('the setup: against the computer by default, a friend at a tap; the clubs to pick', (t) async {
    await t.pumpWidget(await app(const SimSetupScreen(), overrides: [simClubsProvider.overrideWith((ref, q) async => clubs)]));
    await t.pumpAndSettle();
    expect(find.text('ضد الكمبيوتر'), findsOneWidget);
    expect(find.text('Liverpool'), findsWidgets);
    expect(find.text('Arsenal'), findsOneWidget);
    expect(find.text('خصم عشوائي'), findsOneWidget);
    expect(find.text('ابدأ المحاكاة'), findsOneWidget);
    await t.tap(find.text('ضد صديق'));
    await t.pumpAndSettle();
    expect(find.text('افتح الغرفة وادعُ صديقك'), findsOneWidget);
    expect(find.text('بانتظار صديقك…'), findsOneWidget);
  });

  testWidgets('the simulator switched off on the server says so', (t) async {
    await t.pumpWidget(
      await app(
        const SimSetupScreen(),
        overrides: [simClubsProvider.overrideWith((ref, q) async => throw const ApiError('x', status: 404))],
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('المحاكي غير مفعّل على السيرفر بعد'), findsOneWidget);
  });

  testWidgets('the face-off: both clubs, their lines, the way in and the invite', (t) async {
    await t.pumpWidget(
      await app(
        SimVersusScreen(home: clubs[0], away: clubs[1], friend: true, matchUrl: 'https://x/sim/1', inviteUrl: 'https://x/sim/1?seat=a'),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Liverpool'), findsOneWidget);
    expect(find.text('Arsenal'), findsOneWidget);
    expect(find.text('هجوم'), findsOneWidget);
    expect(find.text('ابدأ المحاكاة'), findsOneWidget);
    expect(find.text('أرسل الدعوة'), findsOneWidget);
  });
}
