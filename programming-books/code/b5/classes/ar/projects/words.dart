const text =
    'قال بِت إن القهوة جيدة ثم قال بِت إن الشاي جيد ثم قال إن الكيك جيد جداً';

void main() {
  var words = text.split(' ');
  // عُدّ كل كلمة: ابدأ من 0 أول مرة تظهر فيها.
  var counts = <String, int>{};
  for (var w in words) {
    counts[w] = (counts[w] ?? 0) + 1;
  }
  print('${words.length} كلمة، ${counts.length} مختلفة');

  // رتّب المدخلات من الأكثر استخداماً نزولاً.
  var sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  print('الأكثر استخداماً:');
  for (var e in sorted.take(3)) {
    print('  ${e.key}: ${e.value}');
  }
  print(words.toSet().length == counts.length);
}
