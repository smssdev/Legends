// خطأ من صنعنا، برسالة يفهمها الناس.
class OutOfMilk implements Exception {
  final String drink;
  OutOfMilk(this.drink);

  @override
  String toString() => 'نفد الحليب ($drink)';
}

Future<String> brew(String drink) async {
  await Future.delayed(Duration(milliseconds: 100));
  if (drink == 'لاتيه') throw OutOfMilk(drink);
  return '$drink جاهز';
}

Future<void> serve(String drink) async {
  // الخطأ في الـ Future يصل عند await، فتلتقطه try.
  try {
    var cup = await brew(drink);
    print(cup);
  } on OutOfMilk catch (e) {
    print('نعتذر: $e');
  } finally {
    // finally تعمل في الحالتين: نظّف الآلة.
    print('  نُظّفت الآلة');
  }
}

Future<void> main() async {
  await serve('شاي');
  await serve('لاتيه');
}
