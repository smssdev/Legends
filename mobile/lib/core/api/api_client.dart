import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../settings.dart';
import '../storage/token_store.dart';
import 'api_error.dart';

/// [Sprint 15 F1] The one HTTP client: the API's address, JSON, the coach's language, and his token on every request.
/// A 401 tells the app the token is gone (expired or revoked), so it goes back to the sign-in.
class ApiClient {
  ApiClient(this._tokens, {String? language, void Function()? onUnauthorized, Dio? dio})
    : dio =
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

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) => _call(() => dio.get(path, queryParameters: query));
  Future<Map<String, dynamic>> post(String path, [Object? body]) => _call(() => dio.post(path, data: body));
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
      final data = r.data;
      return data is Map<String, dynamic> ? data : <String, dynamic>{};
    } catch (e) {
      throw ApiError.from(e);
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
  return ApiClient(ref.watch(tokenStoreProvider), language: language, onUnauthorized: () => ref.read(unauthorizedProvider.notifier).fire());
});
