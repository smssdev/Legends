const text =
    'the cat sat on the mat and the cat slept on the mat while the dog sat on the floor';

void main() {
  var words = text.split(' ');
  // Count every word: start at 0 the first time it is seen.
  var counts = <String, int>{};
  for (var w in words) {
    counts[w] = (counts[w] ?? 0) + 1;
  }
  print('${words.length} words, ${counts.length} different');

  // Sort the entries from the most used down.
  var sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  print('most used:');
  for (var e in sorted.take(3)) {
    print('  ${e.key}: ${e.value}');
  }
  print(words.toSet().length == counts.length);
}
