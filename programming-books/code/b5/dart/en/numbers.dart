void main() {
  int cups = 7;
  double price = 12.5;
  num anything = 3;
  bool open = true;
  print(cups);
  print(price);
  print(anything);
  print(open);

  // / always gives a double; ~/ divides and drops what is after the point.
  print(7 / 2);
  print(7 ~/ 2);
  print(7 % 2);

  // Text from a user or a file becomes a number with parse.
  int age = int.parse('34');
  double weight = double.parse('2.75');
  print(age + 1);
  print(weight * 2);

  // Two digits after the point, as text, ready to show.
  print((10 / 3).toStringAsFixed(2));
  print(age.toString() + '!');
}
