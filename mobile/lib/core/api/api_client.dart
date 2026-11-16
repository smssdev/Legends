import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../settings.dart';
import '../storage/token_store.dart';
import 'api_error.dart';
import 'response_cache.dart';

/// [Sprint 15 F1] The one HTTP client: the API's address, JSON, the coach's language, and his token on every request.
/// A 401 tells the app the token is gone (expired or revoked), so it goes back to the sign-in.
class ApiClient {
  ApiClient(
    this._tokens, {
    String? language,
    void Function()? onUnauthorized,
    Dio? dio,
    this.onLink,
    this.cache,
    this.retryDelays = const [Duration(seconds: 1), Duration(seconds: 3)],
  }) : _language = language ?? '',
       dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: AppConfig.apiUrl,
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 30),
             ),
           ) {
    this.dio.options.headers['Accept'] = 'application/json';
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokens.read();
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          if (language != null) options.headers['Accept-Language'] = language;
          handler.next(options);
        },
        onError: (e, handler) {
          if (e.response?.statusCode == 401) onUnauthorized?.call();
          handler.next(e);
        },
      ),
    );
  }

  final Dio dio;
  final TokenStore _tokens;
  final String _language;

  /// [Sprint 61 F9] Told whether the server answered (true) or the network failed (false).
  final void Function(bool online)? onLink;

  /// [Sprint 61 F7] Where the screens' last answers are kept ([getSaved]).
  final ResponseCache? cache;

  /// [Sprint 61 F8] A GET that found no network or a server error is asked again after each of these.
  final List<Duration> retryDelays;

  /// A GET: asked again after [retryDelays] when the network or the server failed (never for a refusal, 4xx), and
  /// stopped by [cancel] (the screen gone).
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query, CancelToken? cancel, Map<String, String>? headers}) async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await _call(
          () => dio.get(
            path,
            queryParameters: query,
            cancelToken: cancel,
            options: headers == null ? null : Options(headers: headers),
          ),
        );
      } on ApiError catch (e) {
        final again = e.offline || (e.status ?? 0) >= 500;
        if (!again || attempt >= retryDelays.length || (cancel?.isCancelled ?? false)) rethrow;
        await Future<void>.delayed(retryDelays[attempt]);
        if (cancel?.isCancelled ?? false) rethrow;
      }
    }
  }

  /// [Sprint 61 F7] A screen's GET from its last answer on the phone, at once, while the server is asked behind it;
  /// when the server's answer differs, it is kept and [onNewer] rebuilds the screen (which then reads it). Without a
  /// saved answer, as [get].
  Future<Map<String, dynamic>> getSaved(
    String path, {
    Map<String, dynamic>? query,
    required void Function() onNewer,
    CancelToken? cancel,
  }) async {
    final store = cache;
    if (store == null) return get(path, query: query, cancel: cancel);
    final key = ResponseCache.keyOf(path, query, _language);
    final fresh = store.takeFresh(key);
    if (fresh != null) return fresh;
    final saved = await store.read(key);
    if (saved == null) {
      final r = await get(path, query: query, cancel: cancel);
      await store.write(key, r);
      return r;
    }
    unawaited(() async {
      try {
        final r = await get(path, query: query, cancel: cancel);
        await store.write(key, r);
        if (jsonEncode(r) != jsonEncode(saved)) {
          store.keepFresh(key, r);
          onNewer();
        }
      } on ApiError {
        // No network: the saved answer stays on the screen, and the frame says the connection is lost.
      }
    }());
    return saved;
  }

  Future<Map<String, dynamic>> post(String path, [Object? body, Map<String, String>? headers]) => _call(
    () => dio.post(
      path,
      data: body,
      options: headers == null ? null : Options(headers: headers),
    ),
  );
  Future<Map<String, dynamic>> put(String path, [Object? body]) => _call(() => dio.put(path, data: body));
  Future<Map<String, dynamic>> patch(String path, [Object? body]) => _call(() => dio.patch(path, data: body));
  Future<Map<String, dynamic>> delete(String path, [Object? body]) => _call(() => dio.delete(path, data: body));

  /// A file sent as a form (a picture for the avatar or a group), with its other fields.
  Future<Map<String, dynamic>> upload(String path, String field, String filePath, {Map<String, Object> fields = const {}, String? type}) =>
      _call(
        () async => dio.post(
          path,
          data: FormData.fromMap({
            ...fields,
            field: await MultipartFile.fromFile(filePath, contentType: type == null ? null : DioMediaType.parse(type)),
          }),
        ),
      );

  /// A private file's bytes (a group's picture), with the account's token.
  Future<List<int>> bytes(String path) async {
    try {
      final r = await dio.get<List<int>>(path, options: Options(responseType: ResponseType.bytes));
      return r.data ?? const [];
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<Map<String, dynamic>> _call(Future<Response<dynamic>> Function() send) async {
    try {
      final r = await send();
      onLink?.call(true);
      final data = r.data;
      return data is Map<String, dynamic> ? data : <String, dynamic>{};
    } catch (e) {
      final err = ApiError.from(e);
      // A request cancelled by its screen says nothing of the network.
      if (!(e is DioException && e.type == DioExceptionType.cancel)) onLink?.call(!err.offline);
      throw err;
    }
  }
}

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

/// Signals that the server refused the token (the auth controller listens and signs out).
final unauthorizedProvider = NotifierProvider<UnauthorizedSignal, int>(UnauthorizedSignal.new);

class UnauthorizedSignal extends Notifier<int> {
  @override
  int build() => 0;
  void fire() => state++;
}

final apiProvider = Provider<ApiClient>((ref) {
  final language = ref.watch(settingsProvider.select((s) => s.language));
  return ApiClient(
    ref.watch(tokenStoreProvider),
    language: language,
    onUnauthorized: () => ref.read(unauthorizedProvider.notifier).fire(),
    onLink: (online) => ref.read(onlineProvider.notifier).set(online),
    cache: ref.watch(responseCacheProvider),
  );
});

/// [Sprint 61 F7, F8] What a screen's provider shares: a token that stops its requests when it is disposed, and its
/// saved answer shown first (rebuilt by the server's newer one, and again when the connection comes back).
extension ScreenRequests on Ref {
  CancelToken cancelToken() {
    final token = CancelToken();
    onDispose(token.cancel);
    return token;
  }

  Future<Map<String, dynamic>> saved(String path, {Map<String, dynamic>? query}) =>
      read(apiProvider).getSaved(path, query: query, onNewer: newerRebuilds(), cancel: cancelToken());

  /// The callback that rebuilds this provider with the server's newer answer; it also asks again when the connection
  /// comes back.
  void Function() newerRebuilds() {
    watch(reconnectedProvider);
    return () {
      if (mounted) invalidateSelf();
    };
  }

  /// [Sprint 74 P8] An answer kept a while after its last screen goes (two minutes), so coming back to a section shows
  /// it at once with no request: a league's team, tactics, table and fixtures were asked for again on every return.
  /// Called once the answer is in (a failure is never kept). An action still refreshes it (`invalidate`), and so does a
  /// newer answer from the server.
  void staysFor([Duration time = const Duration(minutes: 2)]) {
    final link = keepAlive();
    Timer? end;
    onCancel(() => end = Timer(time, link.close));
    onResume(() => end?.cancel());
    onDispose(() => end?.cancel());
  }
}
