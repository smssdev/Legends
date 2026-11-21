void main() {
  int cups = 7;
  double price = 12.5;
  num anything = 3;
  bool open = true;
  print(cups);
  print(price);
  print(anything);
  print(open);

  // / تعطي double دائماً؛ و~/ تقسم وتحذف ما بعد الفاصلة.
  print(7 / 2);
  print(7 ~/ 2);
  print(7 % 2);

  // النص القادم من المستخدم أو من ملف يصير رقماً بـ parse.
  int age = int.parse('34');
  double weight = double.parse('2.75');
  print(age + 1);
  print(weight * 2);

  // رقمان بعد الفاصلة، نصاً جاهزاً للعرض.
  print((10 / 3).toStringAsFixed(2));
  print(age.toString() + '!');
}
