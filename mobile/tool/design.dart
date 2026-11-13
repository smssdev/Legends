// [Sprint 54 F4] The design system binds the app as it binds the web (web/scripts/design.mjs): a screen takes its
// colours from the palette (context.palette, GlmBroadcast, lib/ui/art_palette.dart) and its sizes from the type roles
// (glmText, context.type), never `Color(0x…)` or `fontSize:` of its own. Every .dart under lib/ but lib/ui/ (where the
// shapes live) and the generated l10n is read. [Sprint 60 F2] Every screen moved: no exception any more, any hit fails.

import 'dart:io';

final rules = {'color': RegExp(r'Color\(0x'), 'font-size': RegExp(r'fontSize:')};

void main(List<String> args) {
  final now = <String, Map<String, int>>{};
  final files = Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  for (final f in files) {
    final rel = f.path.replaceAll('\\', '/');
    if (rel.startsWith('lib/ui/') || rel.startsWith('lib/l10n/') || rel.endsWith('.g.dart')) continue;
    final text = f.readAsStringSync();
    // [Sprint 59 F4] A part is reported with its library.
    final of = RegExp(r"^part of '([^']+)';", multiLine: true).firstMatch(text);
    final key = of == null ? rel : '${rel.substring(0, rel.lastIndexOf('/') + 1)}${of[1]}';
    final src = text.split('\n').where((l) => !l.trimLeft().startsWith('//')).join('\n');
    final hit = now.putIfAbsent(key, () => <String, int>{});
    rules.forEach((k, re) {
      final n = re.allMatches(src).length;
      if (n > 0) hit[k] = (hit[k] ?? 0) + n;
    });
  }
  now.removeWhere((_, hit) => hit.isEmpty);
  if (now.isNotEmpty) {
    stderr.writeln(
      "design: a screen set its own colour or size (use context.palette / glmText; see tool/design.dart):\n  ${now.entries.map((e) => '${e.key}: ${e.value}').join('\n  ')}",
    );
    exitCode = 1;
    return;
  }
  stdout.writeln('design: OK (every screen on the palette and the type scale)');
}
