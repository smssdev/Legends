// [Sprint 59 F9] No Arabic word written in the app's code: every word is in lib/l10n/ (app_ar.arb and app_en.arb).
// `dart run tool/arabic.dart` fails on any Arabic letter inside a string literal of lib/ outside l10n/. The exceptions:
// the game's name, «العربية» in the language picker, the story words (generated from the web's dictionary by
// `npm run i18n`) and a line that says why with `l10n-ok`.
import 'dart:io';

final _arabic = RegExp('[؀-ۿ]');
final _literal = RegExp(
  r"'(?:[^'\\]|\\.)*'"
  '|'
  r'"(?:[^"\\]|\\.)*"',
);
const _allowed = ['المدرب الأسطورة', 'العربية'];
const _generated = ['lib/l10n/', 'lib/features/match/feed/story_words.dart'];

void main() {
  final found = <String>[];
  for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
    final path = f.path.replaceAll(r'\', '/');
    if (_generated.any(path.startsWith)) continue;
    final lines = f.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trimLeft().startsWith('//') || line.contains('l10n-ok')) continue;
      for (final m in _literal.allMatches(line)) {
        var s = m[0]!;
        for (final a in _allowed) {
          s = s.replaceAll(a, '');
        }
        if (_arabic.hasMatch(s)) found.add('$path:${i + 1}: ${line.trim()}');
      }
    }
  }
  if (found.isEmpty) {
    stdout.writeln('arabic: OK');
    return;
  }
  stderr
    ..writeln('arabic: ${found.length} Arabic text(s) in the code; move them to lib/l10n/app_ar.arb and app_en.arb:')
    ..writeln(found.join('\n'));
  exitCode = 1;
}
