// Prices in whole pounds; Chapter 3 keeps them in a class.
const latte = 45;
const cookie = 20;
const cake = 60;
const width = 26;

// The day decides the discount: 20% on Fridays, 10% on Saturdays.
int discountPercent(String day) => switch (day) {
  'friday' => 20,
  'saturday' => 10,
  _ => 0,
};

// One line of the receipt: name on the left, amount on the right.
String line(String name, int amount) =>
    name.padRight(width - 8) + amount.toString().padLeft(8);

void printReceipt({
  required String day,
  int lattes = 0,
  int cookies = 0,
  int cakes = 0,
}) {
  var subtotal = lattes * latte + cookies * cookie + cakes * cake;
  var discount = subtotal * discountPercent(day) ~/ 100;
  // Service is rounded to the nearest pound.
  var service = ((subtotal - discount) * 0.12).round();
  var total = subtotal - discount + service;

  print('=' * width);
  print('BIT CAFÉ · $day');
  print('-' * width);
  if (lattes > 0) print(line('$lattes × Latte', lattes * latte));
  if (cookies > 0) print(line('$cookies × Cookie', cookies * cookie));
  if (cakes > 0) print(line('$cakes × Cake', cakes * cake));
  print('-' * width);
  print(line('Subtotal', subtotal));
  if (discount > 0) print(line('Discount', -discount));
  print(line('Service 12%', service));
  print(line('To pay', total));
  print('=' * width);
}

void main() {
  printReceipt(day: 'friday', lattes: 2, cookies: 3);
  printReceipt(day: 'monday', cakes: 1, lattes: 1);
}
