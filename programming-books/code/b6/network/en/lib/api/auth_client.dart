import 'dart:async';

import 'package:http/http.dart' as http;

// Adds the token to every request; on a 401, refreshes once and tries again.
class AuthClient extends http.BaseClient {
  AuthClient(this.inner, this._token, {required this.refresh});

  final http.Client inner;
  final Future<String> Function() refresh;
  String _token;
  Future<String>? _refreshing;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await inner.send(_withToken(request, _token));
    if (response.statusCode != 401) {
      return response;
    }
    // One refresh at a time: the requests that arrive meanwhile wait for the same one.
    final sentWith = _token;
    _refreshing ??= refresh().whenComplete(() => _refreshing = null);
    _token = sentWith == _token ? await _refreshing! : _token;
    return inner.send(_withToken(request, _token));
  }

  http.BaseRequest _withToken(http.BaseRequest original, String token) {
    final copy = http.Request(original.method, original.url)
      ..headers.addAll(original.headers)
      ..headers['authorization'] = 'Bearer $token';
    if (original is http.Request) {
      copy.bodyBytes = original.bodyBytes;
    }
    return copy;
  }
}
