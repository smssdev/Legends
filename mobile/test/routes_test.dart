// [Sprint 66 T8] The app's router as a player meets it: a guest goes to the sign-in (and from an invitation link, back
// to it once signed in), a signed-in coach goes home, a link to no page says so, and a token the server refuses (401)
// signs the coach out. The real router and account controller; only the server is scripted.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/api/api_client.dart';
import 'package:glm/core/api/response_cache.dart';
import 'package:glm/core/settings.dart';
import 'package:glm/core/storage/token_store.dart';
import 'package:glm/features/health/intro_screen.dart';
import 'package:glm/features/health/status_screens.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/router.dart';
import 'package:glm/ui/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The server: /bootstrap answers the account (or 401 once `refuse` is on); everything else is unavailable.
class _Server implements HttpClientAdapter {
  _Server(this.me);

  final Map<String, dynamic> me;
  bool refuse = false;
  final asked = <String>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    asked.add(options.path);
    final (code, body) = refuse
        ? (401, <String, dynamic>{'message': 'unauthenticated'})
        : options.path == '/bootstrap'
        ? (200, <String, dynamic>{'user': me['user'], 'wallet': null, 'home': null, 'unread': 0, 'config': <String, dynamic>{}})
        : (503, <String, dynamic>{'message': 'down'});
    return ResponseBody.fromString(
      jsonEncode(body),
      code,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Played extends IntroDone {
  @override
  bool build() => true;
}

void main() {
  final me = jsonDecode(File('test/fixtures/auth_me.json').readAsStringSync()) as Map<String, dynamic>;
  late _Server server;
  late GoRouter router;

  Future<void> start(WidgetTester t, {required bool signedIn}) async {
    FlutterSecureStorage.setMockInitialValues(signedIn ? {'glm.token': 't'} : {});
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final dir = Directory.systemTemp.createTempSync('routes');
    // Signing out clears the saved answers (the folder with them).
    addTearDown(() => dir.existsSync() ? dir.deleteSync(recursive: true) : null);
    server = _Server(me);
    final tokens = TokenStore();
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          tokenStoreProvider.overrideWithValue(tokens),
          responseCacheProvider.overrideWithValue(ResponseCache(dir: () async => dir)),
          introDoneProvider.overrideWith(_Played.new),
          apiProvider.overrideWith(
            (ref) => ApiClient(
              tokens,
              language: 'ar',
              dio: Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = server,
              onUnauthorized: () => ref.read(unauthorizedProvider.notifier).fire(),
              retryDelays: const [],
            ),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            router = ref.watch(routerProvider);
            return MaterialApp.router(
              routerConfig: router,
              theme: glmTheme(day: false),
              locale: const Locale('ar'),
              supportedLocales: L.supportedLocales,
              localizationsDelegates: L.localizationsDelegates,
            );
          },
        ),
      ),
    );
    await settle(t);
  }

  String here() => router.routerDelegate.currentConfiguration.uri.toString();

  Future<void> go(WidgetTester t, String to) async {
    router.go(to);
    await settle(t);
  }

  testWidgets('a guest goes to the sign-in, and an invitation link waits for him there', (t) async {
    await start(t, signedIn: false);
    expect(here(), '/login');
    await go(t, '/inbox');
    expect(here(), '/login');
    await go(t, '/join/ABCD2345');
    expect(here(), '/login?from=${Uri.encodeComponent('/join/ABCD2345')}');
  });

  testWidgets('a signed-in coach goes home, lands on the link he came from, and a wrong link says so', (t) async {
    await start(t, signedIn: true);
    expect(server.asked, contains('/bootstrap'));
    expect(here(), '/');
    await go(t, '/login?from=${Uri.encodeComponent('/join/ABCD2345')}');
    expect(here(), '/join/ABCD2345');
    await go(t, '/register');
    expect(here(), '/');
    await go(t, '/no/such/page');
    expect(find.byType(NotFoundScreen), findsOneWidget);
  });

  testWidgets('a token the server refuses (401) signs the coach out, back to the sign-in', (t) async {
    await start(t, signedIn: true);
    expect(here(), '/');
    server.refuse = true;
    final container = ProviderScope.containerOf(t.element(find.byType(MaterialApp)));
    await t.runAsync(() async {
      await expectLater(container.read(apiProvider).get('/home'), throwsA(anything));
    });
    await settle(t);
    expect(here(), '/login');
    expect(await container.read(tokenStoreProvider).read(), isNull);
  });
}

/// Frames for a while (the screens keep spinners and pulses: never settles on its own).
Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 20; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}
