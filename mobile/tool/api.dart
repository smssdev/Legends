// [Sprint 59 F1] The API's models from its contract: `dart run tool/api.dart` reads ../docs/api/openapi.yaml and writes
// lib/api/gen/models.g.dart, a class for each schema (and each object inside one) with a tolerant fromJson
// (lib/api/read.dart). mobile.yml runs it and fails if the file changed: a field renamed in the contract breaks the code
// that reads it at `flutter analyze`, as `npm run api` does for the web. Our own generator (no build_runner): plain
// classes, nothing to install.
import 'dart:io';

import 'package:yaml/yaml.dart';

const _out = 'lib/api/gen/models.g.dart';
const _keywords = {
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'base',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'get',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'new',
  'null',
  'on',
  'operator',
  'part',
  'required',
  'rethrow',
  'return',
  'sealed',
  'set',
  'static',
  'super',
  'switch',
  'this',
  'throw',
  'true',
  'try',
  'typedef',
  'var',
  'void',
  'when',
  'while',
  'with',
  'yield',
  'hashCode',
  'runtimeType',
  'toString',
  'noSuchMethod',
};

late Map<dynamic, dynamic> _schemas;
final _classes = <String, String>{};

String _pascal(String s) =>
    s.split(RegExp(r'[^A-Za-z0-9]+')).where((p) => p.isNotEmpty).map((p) => p[0].toUpperCase() + p.substring(1)).join();

String _field(String s) {
  final p = _pascal(s);
  var f = p.isEmpty ? 'value' : p[0].toLowerCase() + p.substring(1);
  if (RegExp(r'^[0-9]').hasMatch(f)) f = 'n$f';
  return _keywords.contains(f) ? '${f}_' : f;
}

/// OpenAPI 3.1's `type: [integer, 'null']` as 3.0's `type: integer, nullable: true` (one shape for the rest).
Object? _plain(Object? s) {
  // `allOf: [one $ref]` (OpenAPI 3.0's way to make a ref nullable) is that ref.
  if (s is Map && s['allOf'] is List && (s['allOf'] as List<dynamic>).length == 1 && s['properties'] == null) {
    final only = (s['allOf'] as List<dynamic>).single;
    if (_refName(only) != null) {
      return {r'$ref': (only as Map<dynamic, dynamic>)[r'$ref'], 'nullable': s['nullable'], 'description': s['description']};
    }
  }
  if (s is! Map || s['type'] is! List) return s;
  final types = [for (final t in s['type'] as List<dynamic>) '$t'];
  final real = types.where((t) => t != 'null').toList();
  return {...s, 'type': real.length == 1 ? real.single : null, if (types.contains('null')) 'nullable': true};
}

String? _refName(Object? s) {
  if (s is Map && s[r'$ref'] is String) return (s[r'$ref'] as String).split('/').last;
  return null;
}

/// The schema with its allOf merged (refs resolved).
Map<dynamic, dynamic> _merged(Map<dynamic, dynamic> s) {
  final all = s['allOf'];
  if (all is! List) return s;
  final props = <dynamic, dynamic>{}, required = <dynamic>{};
  for (final part in [...all, s]) {
    final p = _refName(part) != null ? _merged(_schemas[_refName(part)] as Map<dynamic, dynamic>) : part as Map<dynamic, dynamic>;
    if (p['properties'] is Map) props.addAll(p['properties'] as Map<dynamic, dynamic>);
    if (p['required'] is List) required.addAll(p['required'] as List<dynamic>);
  }
  return {'type': 'object', 'properties': props, 'required': required.toList(), 'nullable': s['nullable']};
}

bool _isObject(Map<dynamic, dynamic> s) => s['properties'] is Map || s['allOf'] is List;

/// A value's Dart type and its reader for a list or a map (one value, not a field).
({String type, String read}) _value(Object? raw, String nameIfObject) {
  final schema = _plain(raw);
  if (schema is! Map) return (type: 'Object?', read: 'JsonReader.anyOf');
  final ref = _refName(schema);
  if (ref != null) {
    final target = _schemas[ref];
    if (target is Map && _isObject(target)) return (type: ref, read: '$ref.fromJson');
    return _value(target, ref);
  }
  final nullable = schema['nullable'] == true;
  switch (schema['type']) {
    case 'integer':
      return nullable ? (type: 'int?', read: 'JsonReader.intOrNullOf') : (type: 'int', read: 'JsonReader.intOf');
    case 'number':
      return (type: 'double', read: 'JsonReader.numOf');
    case 'string':
      return nullable ? (type: 'String?', read: 'JsonReader.stringOrNullOf') : (type: 'String', read: 'JsonReader.stringOf');
    case 'boolean':
      return (type: 'bool', read: 'JsonReader.boolOf');
  }
  if (_isObject(schema)) {
    _class(nameIfObject, schema);
    return (type: nameIfObject, read: '$nameIfObject.fromJson');
  }
  return (type: 'Object?', read: 'JsonReader.anyOf');
}

/// A field's type (without the nullability) and its read from the JsonReader `r`.
String _read(String key, Object? raw, bool required, String owner, void Function(String type, bool nullable) typed) {
  final schema = _plain(raw);
  final s = schema is Map ? schema : const <dynamic, dynamic>{};
  final ref = _refName(s);
  final Map<dynamic, dynamic> target = ref == null ? s : (_plain(_schemas[ref]) as Map<dynamic, dynamic>? ?? const {});
  final nullable = !required || s['nullable'] == true || target['nullable'] == true;
  final q = nullable ? 'OrNull' : '';
  final k = "'$key'";
  if (ref != null && _isObject(target)) {
    typed(ref, nullable);
    return 'r.object$q($k, $ref.fromJson)';
  }
  switch (target['type']) {
    case 'integer':
      typed('int', nullable);
      return nullable ? 'r.intOrNull($k)' : 'r.int_($k)';
    case 'number':
      typed('double', nullable);
      return nullable ? 'r.numOrNull($k)' : 'r.num_($k)';
    case 'string':
      typed('String', nullable);
      return nullable ? 'r.stringOrNull($k)' : 'r.string($k)';
    case 'boolean':
      typed('bool', nullable);
      return nullable ? 'r.boolOrNull($k)' : 'r.bool_($k)';
    case 'array':
      final item = _value(target['items'], '$owner${_pascal(key)}Item');
      typed('List<${item.type}>', nullable);
      return 'r.list$q($k, ${item.read})';
  }
  if (_isObject(target)) {
    final name = '$owner${_pascal(key)}';
    _class(name, target);
    typed(name, nullable);
    return 'r.object$q($k, $name.fromJson)';
  }
  final extra = target['additionalProperties'];
  if (extra is Map) {
    final v = _value(extra, '$owner${_pascal(key)}Value');
    typed('Map<String, ${v.type}>', nullable);
    return 'r.map$q($k, ${v.read})';
  }
  if (target['type'] == 'object') {
    typed('Map<String, Object?>', nullable);
    return 'r.map$q($k, JsonReader.anyOf)';
  }
  typed('Object?', false);
  return 'r.any($k)';
}

void _class(String name, Map<dynamic, dynamic> raw) {
  if (_classes.containsKey(name)) return;
  _classes[name] = '';
  final s = _merged(raw);
  final props = (s['properties'] as Map<dynamic, dynamic>?) ?? const {};
  final required = {...(s['required'] as List<dynamic>? ?? const [])};
  final fields = <String>[], params = <String>[], reads = <String>[];
  final keys = props.keys.map((k) => '$k').toList()..sort();
  final used = <String>{};
  for (final key in keys) {
    var f = _field(key);
    while (!used.add(f)) {
      f = '${f}_';
    }
    final schema = props[key];
    final read = _read(key, schema, required.contains(key), name, (type, nullable) {
      final t = nullable && !type.endsWith('?') ? '$type?' : type;
      final doc = schema is Map && schema['description'] is String ? (schema['description'] as String).split('\n').first : null;
      if (doc != null) fields.add('  /// ${doc.replaceAll('\r', '')}');
      fields.add('  final $t $f;');
      params.add(t.endsWith('?') ? 'this.$f' : 'required this.$f');
    });
    reads.add('      $f: $read,');
  }
  final b = StringBuffer();
  final doc = raw['description'] is String ? (raw['description'] as String).split('\n').first : null;
  if (doc != null) b.writeln('/// $doc');
  b.writeln('class $name {');
  b.writeln(params.isEmpty ? '  const $name();' : '  const $name({${params.join(', ')}});');
  b.writeln();
  b.writeln('  factory $name.fromJson(Object? json) {');
  b.writeln("    final r = JsonReader(json, '$name');");
  b.writeln(reads.isEmpty ? '    return const $name();' : '    return $name(\n${reads.join('\n')}\n    );');
  b.writeln('  }');
  if (fields.isNotEmpty) b.writeln();
  for (final f in fields) {
    b.writeln(f);
  }
  b.writeln('}');
  _classes[name] = b.toString();
}

void main() {
  final api = loadYaml(File('../docs/api/openapi.yaml').readAsStringSync()) as YamlMap;
  _schemas = (api['components'] as YamlMap)['schemas'] as YamlMap;
  final names = _schemas.keys.map((k) => '$k').toList()..sort();
  for (final n in names) {
    final s = _schemas[n];
    if (s is Map && _isObject(s)) _class(n, s);
  }
  // [Sprint 59 F1] A GET's own inline answer too, named after its path without its parameters: GET /rankings/coaches
  // answers RankingsCoachesAnswer, GET /leagues/{league}/team/summary LeaguesTeamSummaryAnswer.
  final paths = api['paths'] as YamlMap;
  for (final path in paths.keys.map((k) => '$k').toList()..sort()) {
    Object? at(Object? m, String k) => m is Map<dynamic, dynamic> ? m[k] : null;
    final schema = at(at(at(at(at(paths[path], 'get'), 'responses'), '200'), 'content'), 'application/json');
    final inner = at(schema, 'schema');
    if (inner is! Map<dynamic, dynamic> || _refName(inner) != null || !_isObject(inner)) continue;
    // A path ending on a parameter (one of a list) says so: /leagues/{league}/clubs/{club} is LeaguesClubsByClubAnswer.
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    final last = parts.isNotEmpty && parts.last.startsWith('{') ? '_by_${parts.last.substring(1, parts.last.length - 1)}' : '';
    final name = '${_pascal(parts.where((p) => !p.startsWith('{')).join('_') + last)}Answer';
    if (!_classes.containsKey(name)) _class(name, inner);
  }
  // [Sprint 59 F1] A shared response's own inline object too (components/responses), as `<Name>Answer`.
  final responses = (api['components'] as YamlMap)['responses'] as YamlMap? ?? YamlMap();
  for (final n in responses.keys.map((k) => '$k').toList()..sort()) {
    final r = responses[n];
    final content = (r is Map<dynamic, dynamic>) ? r['content'] as Map<dynamic, dynamic>? : null;
    final schema = (content?['application/json'] as Map<dynamic, dynamic>?)?['schema'];
    if (schema is Map<dynamic, dynamic> && _refName(schema) == null && _isObject(schema)) _class('${n}Answer', schema);
  }
  final out = StringBuffer()
    ..writeln('// GENERATED by tool/api.dart from docs/api/openapi.yaml: do not edit (dart run tool/api.dart).')
    ..writeln('// ignore_for_file: unused_import, comment_references')
    ..writeln()
    ..writeln("import '../read.dart';")
    ..writeln();
  final sorted = _classes.keys.toList()..sort();
  out.writeAll(sorted.map((k) => _classes[k]), '\n');
  File(_out)
    ..createSync(recursive: true)
    ..writeAsStringSync(out.toString());
  // Formatted as the rest of the code, so the check after it compares like with like.
  Process.runSync('dart', ['format', _out]);
  stdout.writeln('api: ${_classes.length} models → $_out');
}
