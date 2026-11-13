import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/api/api_client.dart';
import 'package:glm/core/storage/token_store.dart';
import 'package:glm/features/match/live_screen.dart';
import 'package:glm/features/match/sim_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glm/core/settings.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/theme.dart';
import 'package:glm/ui/widgets/brand.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> json(String name) => jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Map<String, dynamic>;

/// The simulator's API with real answers from a local server (a solo match, Real Madrid against the computer).
class _Sim implements HttpClientAdapter {
  final List<String> asked = [];
  final List<Object?> bodies = [];
  final List<String?> seats = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    asked.add('${options.method} ${options.path}');
    bodies.add(options.data);
    seats.add(options.headers['X-Seat'] as String?);
    final body = switch (options.path) {
      final p when p.endsWith('/ticks') => json('sim_ticks'),
      final p when p.endsWith('/actions') => {'target_tick': 2, 'duplicate': false},
      _ => json('sim_view'),
    };
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  ApiClient client(_Sim server) => ApiClient(
    TokenStore(),
    dio: Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = server,
    retryDelays: const [],
  );

  test('[Sprint 61 F10] a solo sim match on the live screen: its view, its minutes paced here, the coach\'s orders', () async {
    final server = _Sim();
    final id = json('sim_view')['id'] as String;
    final handle = SimMatches.handle(id, null);
    expect(handle, isNegative, reason: 'a sim match never takes a league match\'s number');
    expect(SimMatches.of(handle)?.id, id);
    final repo = SimMatchRepository(client(server), handle, id, null);

    final view = await repo.show(handle);
    expect(view.id, handle);
    expect(view.you, 'home', reason: 'solo: the coach holds the side he controls');
    expect(view.home.name, 'Real Madrid');
    expect(view.teams['home']!.players, isNotEmpty);
    expect(view.tickMs, 3000);

    // Each poll asks the server for the next minute, and says to ask again when it has played.
    final sync = await repo.live(handle, 0);
    expect(server.asked.last, 'POST /sim/matches/$id/ticks');
    expect(sync.ticks.single.tick, 1);
    expect(sync.pollMs, sync.ticks.single.moment!.ms);
    expect(sync.finished, isFalse);

    await repo.order(handle, {'type': 'sub', 'out': 1, 'in': 2}, key: 'k1');
    expect(server.asked.last, 'POST /sim/matches/$id/actions');
    expect(server.bodies.last, {'type': 'sub', 'out': 1, 'in': 2, 'team': 'home', 'idempotency_key': 'k1'});
    expect(server.seats.last, isNull);
  });

  test('[Sprint 61 F10] a live sim match between friends: its seat on every request', () async {
    final server = _Sim();
    final repo = SimMatchRepository(client(server), SimMatches.handle('m1', 'seat-a'), 'm1', 'seat-a');
    await repo.show(0);
    await repo.react(0, 'fire');
    expect(server.seats, ['seat-a', 'seat-a']);
    expect(server.asked.last, 'POST /sim/matches/m1/reactions');
  });

  testWidgets('[Sprint 61 F10] the live screen plays a sim match in the app, its orders in their drawer', (t) async {
    final server = _Sim();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    t.view.physicalSize = const Size(844, 390) * 2;
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    ClubCrest.loadFromNetwork = false;
    final id = json('sim_view')['id'] as String;
    await t.pumpWidget(
      ProviderScope(
        overrides: [preferencesProvider.overrideWithValue(prefs), apiProvider.overrideWithValue(client(server))],
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
          home: LiveMatchScreen(matchId: SimMatches.handle(id, null)),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(server.asked, contains('GET /sim/matches/$id'));
    expect(server.asked, contains('POST /sim/matches/$id/ticks'));
    expect(find.text('RMA'), findsWidgets);
    // The coach's orders, without the league's timeout.
    await t.tap(find.text('الأوامر'));
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('التكتيك'), findsOneWidget);
    expect(find.text('وقت مستقطع'), findsNothing);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });
}
