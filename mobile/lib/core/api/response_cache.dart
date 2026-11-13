import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../hash.dart';

/// [Sprint 61 F7] The last answer of a screen's GET, kept on the phone (a small JSON file a path), so the screen shows
/// it at once and asks the server behind it. Shown only: every action still asks the server. Forgotten with the
/// account (sign-out) and kept apart by language.
class ResponseCache {
  ResponseCache({Future<Directory> Function()? dir}) : _dir = dir ?? _defaultDir;

  final Future<Directory> Function() _dir;
  Directory? _root;

  /// What was fetched a moment ago (the answer that made a screen rebuild): read once without asking again.
  final Map<String, ({Map<String, dynamic> data, DateTime at})> _fresh = {};

  static Future<Directory> _defaultDir() async => Directory('${(await getApplicationSupportDirectory()).path}/answers');

  static String keyOf(String path, Map<String, dynamic>? query, String language) {
    final q = query == null || query.isEmpty ? '' : '?${(query.keys.toList()..sort()).map((k) => '$k=${query[k]}').join('&')}';
    return fnv64('$language $path$q');
  }

  Future<File> _file(String key) async {
    final root = _root ??= await _dir();
    return File('${root.path}/$key.json');
  }

  Future<Map<String, dynamic>?> read(String key) async {
    try {
      final f = await _file(key);
      if (!f.existsSync()) return null;
      final data = jsonDecode(await f.readAsString());
      return data is Map<String, dynamic> ? data : null;
    } catch (_) {
      return null; // a broken file is no answer
    }
  }

  Future<void> write(String key, Map<String, dynamic> data) async {
    try {
      final f = await _file(key);
      await f.parent.create(recursive: true);
      await f.writeAsString(jsonEncode(data));
    } catch (_) {
      // A phone that cannot write keeps working, only without the saved answer.
    }
  }

  void keepFresh(String key, Map<String, dynamic> data) => _fresh[key] = (data: data, at: DateTime.now());

  Map<String, dynamic>? takeFresh(String key) {
    final f = _fresh.remove(key);
    return f != null && DateTime.now().difference(f.at) < const Duration(seconds: 5) ? f.data : null;
  }

  Future<void> clear() async {
    _fresh.clear();
    try {
      final root = _root ??= await _dir();
      if (root.existsSync()) await root.delete(recursive: true);
    } catch (_) {}
  }
}

final responseCacheProvider = Provider<ResponseCache>((ref) => ResponseCache());

/// [Sprint 61 F9] Whether the server answers: false after a request found no network, true again at the next answer.
final onlineProvider = NotifierProvider<OnlineSignal, bool>(OnlineSignal.new);

class OnlineSignal extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool online) {
    if (online == state) return;
    state = online;
    if (online) ref.read(reconnectedProvider.notifier).bump();
  }
}

/// Counts the returns from no network: a screen that watches it asks again when the connection comes back.
final reconnectedProvider = NotifierProvider<Reconnected, int>(Reconnected.new);

class Reconnected extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}
