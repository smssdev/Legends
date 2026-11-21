double price({required int cups, double each = 12.5}) => cups * each;

void main() {
  print(price(each: 20));
}
