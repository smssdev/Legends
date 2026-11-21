int square(int n) {
  return n * n;
}

// One expression? The arrow => replaces { return ...; }.
int cube(int n) => n * n * n;

// Named parameters are written with their names; required ones must be given.
double price({required int cups, double each = 12.5}) => cups * each;

// Optional positional parameters go in square brackets.
String greet(String name, [String greeting = 'Hello']) => '$greeting, $name!';

void main() {
  print(square(4));
  print(cube(3));
  print(price(cups: 2));
  print(price(each: 20, cups: 3));
  print(greet('Sara'));
  print(greet('Omar', 'Good morning'));
}
