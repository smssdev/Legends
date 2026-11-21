void main() {
  var name = 'سارة';
  var items = 3;
  var price = 12.5;

  // $name تضع متغيراً في النص؛ و${...} أي تعبير.
  print('أهلاً بعودتك، $name!');
  print('$items قطع × $price = ${items * price}');
  print('السعر: ${price.toStringAsFixed(2)}');

  // ثلاث علامات تنصيص: نص على عدة أسطر.
  var poem = '''الورد أحمر،
  وDart كذلك،
  لكل قيمة نوع،
  فاعرف نوعك.''';
  print(poem);

  var raw = '  مقهى بِت  ';
  print('[${raw.trim()}]');
  print(raw.trim().toUpperCase());
  print(name.length);
  print(name.contains('سارة'));
  print('7'.padLeft(3, '0'));
}
