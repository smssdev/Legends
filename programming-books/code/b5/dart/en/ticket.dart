void main() {
  var age = 9;
  var isMember = true;

  int price;
  if (age < 4) {
    price = 0;
  } else if (age < 13 || age >= 65) {
    price = 6;
  } else {
    price = 10;
  }

  if (isMember) {
    price = price ~/ 2;
  }

  // condition ? if true : if false, for small choices.
  var kind = age < 18 ? 'Child' : 'Adult';
  var who = isMember ? 'member' : 'guest';
  print('Age $age ($kind, $who) pays $price');
}
