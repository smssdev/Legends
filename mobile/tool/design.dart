// [Sprint 54 F4] The design system binds the app as it binds the web (web/scripts/design.mjs): a screen takes its
// colours from the palette (context.palette, GlmBroadcast …) and its sizes from the type roles (context.type), never
// `Color(0x…)` or `fontSize:` of its own. Every .dart under lib/ but lib/ui/ (where the shapes live) and the generated
// l10n is counted; the files not yet moved are in tool/design-baseline.json, a file may go down, never up, and the list
// shrinks as Sprint 60 moves each screen. `dart run tool/design.dart --write` rewrites it after a migration.
import 'dart:convert';
import 'dart:io';

const baseFile = 'tool/design-baseline.json';
final rules = {'color': RegExp(r'Color\(0x'), 'font-size': RegExp(r'fontSize:')};

void main(List<String> args) {
  final now = <String, Map<String, int>>{};
  final files = Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  for (final f in files) {
    final rel = f.path.replaceAll('\\', '/');
    if (rel.startsWith('lib/ui/') || rel.startsWith('lib/l10n/') || rel.endsWith('.g.dart')) continue;
    final src = f.readAsStringSync().split('\n').where((l) => !l.trimLeft().startsWith('//')).join('\n');
    final hit = <String, int>{};
    rules.forEach((k, re) {
      final n = re.allMatches(src).length;
      if (n > 0) hit[k] = n;
    });
    if (hit.isNotEmpty) now[rel] = hit;
  }
  final sorted = Map.fromEntries(now.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  if (args.contains('--write')) {
    File(baseFile).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(sorted)}\n');
    stdout.writeln('design: ${sorted.length} files not yet on the components, written to $baseFile');
    return;
  }
  final base = (jsonDecode(File(baseFile).readAsStringSync()) as Map<dynamic, dynamic>).map((k, v) => MapEntry(k as String, Map<String, dynamic>.from(v as Map<dynamic, dynamic>)));
  final bad = <String>[];
  sorted.forEach((f, hit) => hit.forEach((k, v) {
        final was = (base[f]?[k] ?? 0) as int;
        if (v > was) bad.add('$f: $k $was → $v');
      }));
  if (bad.isNotEmpty) {
    stderr.writeln("design: a screen set its own colour or size (use context.palette / context.type; see tool/design.dart):\n  ${bad.join('\n  ')}");
    exitCode = 1;
    return;
  }
  stdout.writeln('design: OK (${sorted.length} files still to move)');
}
