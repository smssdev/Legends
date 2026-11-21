void main() {
  // Count from 1 to 3.
  for (var i = 1; i <= 3; i++) {
    print('Round $i');
  }

  // for-in: every item of a list, in order.
  var drinks = ['tea', 'coffee', 'juice'];
  for (var drink in drinks) {
    print(drink);
  }

  // while: repeat as long as the condition is true.
  var cups = 3;
  while (cups > 0) {
    print('Cup $cups');
    cups--;
  }

  // continue skips to the next round; break leaves the loop.
  for (var n = 1; n <= 10; n++) {
    if (n % 2 == 0) continue;
    if (n > 7) break;
    print(n);
  }
}
