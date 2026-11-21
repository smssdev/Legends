void main() {
  var age = 9;
  var isMember = true;

  var price = switch (age) {
    < 4 => 0,
    < 13 || >= 65 => 6,
    _ => 10,
  };
  if (isMember) price = price ~/ 2;
  print('Age $age pays $price');
}
