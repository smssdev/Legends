String plural(int count, String word, {String many = ''}) {
  if (count == 1) return '$count $word';
  return '$count ${many.isEmpty ? '${word}s' : many}';
}

void main() {
  print(plural(1, 'cup'));
  print(plural(2, 'cup'));
  print(plural(0, 'cup'));
  print(plural(2, 'child', many: 'children'));
}
