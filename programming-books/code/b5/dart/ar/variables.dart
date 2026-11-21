void main() {
  // تستنتج Dart النوع من أول قيمة: score من النوع int إلى الأبد.
  var score = 0;
  score = score + 10;
  print(score);

  // أو اكتب النوع بنفسك.
  String name = 'سارة';
  print(name);

  // final: تُضبط مرة واحدة، عند تشغيل البرنامج.
  final joined = DateTime.now().year;
  print(joined > 2000);

  // const: معروفة قبل تشغيل البرنامج، ولا تتغير أبداً.
  const maxPlayers = 4;
  print(maxPlayers);
}
