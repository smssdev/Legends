import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/api/api_client.dart';
import 'package:glm/core/api/api_error.dart';
import 'package:glm/core/config.dart';
import 'package:glm/core/settings.dart';
import 'package:glm/core/sounds.dart';
import 'package:glm/core/storage/token_store.dart';
import 'package:glm/features/auth/account.dart';
import 'package:glm/features/auth/auth_controller.dart';
import 'package:glm/features/auth/auth_repository.dart';
import 'package:glm/features/auth/google_identity.dart';
import 'package:glm/features/auth/ui/login_screen.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/theme.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [X107] Sign in with Google: what the app sends the API, what it keeps, and what the sign-in screen does with each
/// way the sheet can end (an account picked, the sheet closed, Google unable on this phone, the API refusing).

/// A server that answers one thing and notes what it was asked.
class _Server implements HttpClientAdapter {
  _Server(this.status, this.body);

  final int status;
  final Map<String, dynamic> body;
  final asked = <String>[];
  Object? sent;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    asked.add('${options.method} ${options.path}');
    sent = options.data;
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

class _Repo extends Mock implements AuthRepository {}

/// The phone's Google sheet: ends as the test says, and counts the taps that opened it.
class _Google implements GoogleIdentity {
  _Google(this.answer);

  final Future<String?> Function() answer;
  var taps = 0;

  @override
  Future<String?> idToken() {
    taps++;
    return answer();
  }
}

const _googleLabel = 'المتابعة بحساب Google';
const _unknown = 'حدث خطأ، حاول مرة أخرى.';
const _refused = 'تعذر التحقق من حساب جوجل. حاول مجدداً.';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  final me = jsonDecode(File('test/fixtures/auth_me.json').readAsStringSync()) as Map<String, dynamic>;

  AuthRepository repoOn(_Server server, TokenStore tokens) =>
      AuthRepository(ApiClient(tokens, dio: Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = server), tokens);

  test('[X107] the id_token goes to /auth/google/token with the device name, and the token it answers with is kept', () async {
    final server = _Server(200, {'token': 'tok-google', 'user': me['user']});
    final tokens = TokenStore();
    final account = await repoOn(server, tokens).google('ID.TOKEN.FROM.GOOGLE');
    expect(server.asked, ['POST /auth/google/token']);
    expect(server.sent, {'id_token': 'ID.TOKEN.FROM.GOOGLE', 'device_name': AppConfig.deviceName});
    expect(await tokens.read(), 'tok-google');
    expect(account.id, (me['user'] as Map<String, dynamic>)['id']);
  });

  test('[X107] the API refusing the token (422) is an ApiError with its message, and no token is kept', () async {
    final server = _Server(422, {
      'message': _refused,
      'code': 'validation',
      'errors': {
        'id_token': [_refused],
      },
    });
    final tokens = TokenStore();
    await expectLater(
      repoOn(server, tokens).google('forged'),
      throwsA(isA<ApiError>().having((e) => e.status, 'status', 422).having((e) => e.message, 'message', _refused)),
    );
    expect(await tokens.read(), isNull);
  });

  test('[X107] the game\'s web client is the one the token is asked for, and it is Google\'s kind of id', () {
    expect(AppConfig.googleServerClientId, endsWith('.apps.googleusercontent.com'));
  });

  Future<(_Repo, _Google)> open(WidgetTester t, Future<String?> Function() answer) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    GameSounds.enabled = false;
    t.view.physicalSize = const Size(800, 700) * 2;
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    final repo = _Repo();
    when(() => repo.current()).thenAnswer((_) async => null);
    final google = _Google(answer);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(repo),
          googleIdentityProvider.overrideWithValue(google),
        ],
        child: MaterialApp(
          theme: glmTheme(day: true),
          locale: const Locale('ar'),
          supportedLocales: L.supportedLocales,
          localizationsDelegates: const [
            L.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const LoginScreen(),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 600));
    return (repo, google);
  }

  Future<void> tapGoogle(WidgetTester t) async {
    final button = find.text(_googleLabel);
    await t.ensureVisible(button);
    await t.tap(button);
    await t.pump(const Duration(milliseconds: 200));
  }

  testWidgets('[X107] an account picked in Google\'s sheet signs in through the API', (t) async {
    final (repo, google) = await open(t, () async => 'tok');
    when(() => repo.google('tok')).thenAnswer((_) async => const Account(id: 7, name: 'Hamza', username: 'hamza'));
    await tapGoogle(t);
    expect(google.taps, 1);
    verify(() => repo.google('tok')).called(1);
    final container = ProviderScope.containerOf(t.element(find.byType(LoginScreen)));
    expect(container.read(authProvider).value?.id, 7);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('[X107] closing the sheet says nothing and asks the API nothing', (t) async {
    final (repo, google) = await open(t, () async => null);
    await tapGoogle(t);
    expect(google.taps, 1);
    verifyNever(() => repo.google(any()));
    expect(find.text(_unknown), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('[X107] Google unable on this phone shows an error, asks the API nothing, and the button works again', (t) async {
    final (repo, google) = await open(t, () async => throw const GoogleIdentityError('clientConfigurationError'));
    await tapGoogle(t);
    expect(find.text(_unknown), findsOneWidget);
    verifyNever(() => repo.google(any()));
    await tapGoogle(t);
    expect(google.taps, 2, reason: 'the button was left spinning after the failure');
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('[X107] the API refusing the token shows its own message', (t) async {
    final (repo, _) = await open(t, () async => 'forged');
    when(() => repo.google('forged')).thenAnswer((_) async => throw const ApiError(_refused, status: 422));
    await tapGoogle(t);
    expect(find.text(_refused), findsOneWidget);
    final container = ProviderScope.containerOf(t.element(find.byType(LoginScreen)));
    expect(container.read(authProvider).value, isNull);
    await t.pumpWidget(const SizedBox());
  });
}
