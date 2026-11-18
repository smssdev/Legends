import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/api/api_client.dart';
import 'package:glm/core/api/api_error.dart';
import 'package:glm/core/storage/token_store.dart';
import 'package:glm/features/sim/sim_repository.dart';
import 'package:glm/features/sim/sim_setup_screen.dart';
import 'package:glm/features/sim/sim_versus_screen.dart';

import 'screens_test.dart' show app;

/// [Sprint 47] The simulator in the app: the two modes, the teams from the server, the gold button, the face-off.
/// The server's answer to one request, whatever it is.
class _Answer implements HttpClientAdapter {
  _Answer(this.status, this.body);

  final int status;
  final Object body;
  final List<String> asked = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    asked.add('${options.method} ${options.path}');
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// [X109] An answer by the request's path (its end), and every URL asked, with its query.
class _Routes implements HttpClientAdapter {
  _Routes(this.asked, this.bodies);

  final List<String> asked;
  final Map<String, Object> bodies;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    asked.add(options.uri.toString());
    final body = bodies.entries.firstWhere((e) => options.uri.path.endsWith(e.key)).value;
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
  // [X109] The server stores the Latin names only: an Arabic search also sends the Latin names the dictionary matches.
  test('an Arabic search finds the clubs by the names dictionary, by any alef', () {
    const arabic = {
      'Liverpool': '\u0644\u064A\u0641\u0631\u0628\u0648\u0644',
      'Real Madrid': '\u0631\u064A\u0627\u0644 \u0645\u062F\u0631\u064A\u062F',
    };
    expect(clubsNamed(arabic, '\u0644\u064A\u0641\u0631'), ['Liverpool']);
    expect(clubsNamed(arabic, '\u0631\u064A\u0623\u0644'), ['Real Madrid']);
    expect(clubsNamed(arabic, 'Liver'), isEmpty);
    expect(clubsNamed(arabic, '\u0631\u064A\u0627\u0644', max: 0), isEmpty);
  });

  test('the search sends those Latin names to the server, the dictionary fetched once', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final asked = <String>[];
    final answer = _Routes(asked, {
      '/names/ar.json': {
        'clubs': {'Liverpool': '\u0644\u064A\u0641\u0631\u0628\u0648\u0644'},
      },
      '/sim/clubs': [
        {'id': 7, 'name': 'Liverpool', 'code': 'LIV'},
      ],
    });
    final repo = SimRepository(ApiClient(TokenStore(), dio: Dio()..httpClientAdapter = answer));
    expect((await repo.clubs('\u0644\u064A\u0641\u0631\u0628\u0648\u0644')).single.name, 'Liverpool');
    await repo.clubs('\u0644\u064A\u0641\u0631');
    expect(asked.where((a) => a.endsWith('/names/ar.json')), hasLength(1));
    expect(asked.last, contains('names%5B%5D=Liverpool'));
  });

  test('a match made here: its id is the server\'s ULID (a string), and the two seats of a match with a friend', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final answer = _Answer(201, {
      'id': '01JC8Z6K9Q4V2X7M3N5P8R1T0W',
      'seats': {'home': 'h-seat', 'away': 'a-seat'},
      'teams': <String, dynamic>{},
    });
    final repo = SimRepository(ApiClient(TokenStore(), dio: Dio()..httpClientAdapter = answer));
    final m = await repo.create(
      me: const SimClub(id: 1, name: 'Liverpool', code: 'LIV'),
      them: const SimClub(id: 2, name: 'Arsenal', code: 'ARS'),
      friend: true,
    );
    expect(answer.asked, ['POST /sim/matches']);
    expect((m.id, m.home, m.away), ('01JC8Z6K9Q4V2X7M3N5P8R1T0W', 'h-seat', 'a-seat'));
  });

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
        SimVersusScreen(home: clubs[0], away: clubs[1], friend: true, matchPath: '/sim/match/1', inviteUrl: 'https://x/sim/1?seat=a'),
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
