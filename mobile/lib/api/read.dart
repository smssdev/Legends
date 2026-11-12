import 'package:flutter/foundation.dart';

/// [Sprint 59 F2] An answer that does not fit its model: one clear error naming the model and the field, logged once,
/// in place of a cast failing deep in a screen. (Sprint 66 sends these to the server's log.)
class ModelError implements Exception {
  ModelError(this.model, this.field, this.problem);

  final String model, field, problem;

  @override
  String toString() => 'ModelError: $model.$field $problem';
}

/// The errors seen so far (each logged once), for the tests and for Sprint 66's report.
final modelErrors = <String>{};

/// [Sprint 59 F2] Reads one JSON object for a generated model, tolerantly: a field the model does not know is ignored, a
/// missing or wrong optional field reads as null (and is logged), and a missing or wrong required one is a [ModelError].
class JsonReader {
  JsonReader(Object? json, this.model)
    : _j = json is Map<String, dynamic>
          ? json
          : json is Map
          ? json.map((k, v) => MapEntry('$k', v))
          : throw ModelError(model, '', 'is not an object (${json.runtimeType})');

  final Map<String, dynamic> _j;
  final String model;

  T _need<T>(String field, T? Function(Object? v) read) {
    if (!_j.containsKey(field) || _j[field] == null) throw _fail(field, 'is missing');
    final v = read(_j[field]);
    if (v == null) throw _fail(field, 'is not a $T (${_j[field].runtimeType})');
    return v;
  }

  T? _may<T>(String field, T? Function(Object? v) read) {
    final raw = _j[field];
    if (raw == null) return null;
    final v = read(raw);
    if (v == null) _fail(field, 'is not a $T (${raw.runtimeType}), read as null');
    return v;
  }

  ModelError _fail(String field, String problem) {
    final e = ModelError(model, field, problem);
    if (modelErrors.add('$e')) debugPrint('$e');
    return e;
  }

  static int? _int(Object? v) => v is int ? v : (v is num ? v.toInt() : null);
  static double? _num(Object? v) => v is num ? v.toDouble() : null;
  static String? _string(Object? v) => v is String ? v : (v is num || v is bool ? '$v' : null);
  static bool? _bool(Object? v) => v is bool ? v : null;

  int int_(String f) => _need(f, _int);
  int? intOrNull(String f) => _may(f, _int);
  double num_(String f) => _need(f, _num);
  double? numOrNull(String f) => _may(f, _num);
  String string(String f) => _need(f, _string);
  String? stringOrNull(String f) => _may(f, _string);
  bool bool_(String f) => _need(f, _bool);
  bool? boolOrNull(String f) => _may(f, _bool);
  Object? any(String f) => _j[f];

  /// A nested object, read by [read] (another model's fromJson).
  T object<T>(String f, T Function(Object? json) read) => _need(f, (v) => v is Map ? read(v) : null);
  T? objectOrNull<T>(String f, T Function(Object? json) read) => _may(f, (v) => v is Map ? read(v) : null);

  /// A list; an item that does not read is left out (and logged), not the whole answer.
  List<T> list<T>(String f, T Function(Object? item) read) => _need(f, (v) => v is List ? _items(f, v, read) : null);
  List<T>? listOrNull<T>(String f, T Function(Object? item) read) => _may(f, (v) => v is List ? _items(f, v, read) : null);

  List<T> _items<T>(String f, List<dynamic> v, T Function(Object? item) read) {
    final out = <T>[];
    for (final item in v) {
      try {
        out.add(read(item));
      } on ModelError catch (e) {
        _fail('$f[]', '${e.problem} (${e.model}.${e.field}), the item left out');
      }
    }
    return out;
  }

  Map<String, T> map<T>(String f, T Function(Object? v) read) => _need(f, (v) => v is Map ? _entries(v, read) : null);
  Map<String, T>? mapOrNull<T>(String f, T Function(Object? v) read) => _may(f, (v) => v is Map ? _entries(v, read) : null);

  static Map<String, T> _entries<T>(Map<dynamic, dynamic> v, T Function(Object? v) read) => {
    for (final e in v.entries) '${e.key}': read(e.value),
  };

  /// The readers for a list's or a map's values.
  static int intOf(Object? v) => _int(v) ?? (throw ModelError('', '', 'is not an int'));
  static int? intOrNullOf(Object? v) => _int(v);
  static double numOf(Object? v) => _num(v) ?? (throw ModelError('', '', 'is not a number'));
  static String stringOf(Object? v) => _string(v) ?? (throw ModelError('', '', 'is not a string'));
  static String? stringOrNullOf(Object? v) => _string(v);
  static bool boolOf(Object? v) => _bool(v) ?? (throw ModelError('', '', 'is not a bool'));
  static Object? anyOf(Object? v) => v;
}
