void main() {
  var name = 'Sara';
  var items = 3;
  var price = 12.5;

  // $name puts a variable in the text; ${...} any expression.
  print('Welcome back, $name!');
  print('$items items × $price = ${items * price}');
  print('Price: ${price.toStringAsFixed(2)}');

  // Three quotes: text over several lines.
  var poem = '''Roses are red,
  Dart is too,
  every value has a type,
  and so should you.''';
  print(poem);

  var raw = '  bit café  ';
  print('[${raw.trim()}]');
  print(raw.trim().toUpperCase());
  print(name.length);
  print(name.contains('Sara'));
  print('7'.padLeft(3, '0'));
}
