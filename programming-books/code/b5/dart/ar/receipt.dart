// الأسعار بالجنيه الكامل؛ والفصل 3 يضعها في صنف.
const latte = 45;
const cookie = 20;
const cake = 60;
const width = 26;

// اليوم يحدد الخصم: 20% يوم الجمعة، و10% يوم السبت.
int discountPercent(String day) => switch (day) {
  'الجمعة' => 20,
  'السبت' => 10,
  _ => 0,
};

// سطر واحد من الفاتورة: الاسم في جهة، والمبلغ في الأخرى.
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
  // تُقرّب الخدمة إلى أقرب جنيه.
  var service = ((subtotal - discount) * 0.12).round();
  var total = subtotal - discount + service;

  print('=' * width);
  print('مقهى بِت · $day');
  print('-' * width);
  if (lattes > 0) print(line('$lattes × لاتيه', lattes * latte));
  if (cookies > 0) print(line('$cookies × كوكيز', cookies * cookie));
  if (cakes > 0) print(line('$cakes × كيك', cakes * cake));
  print('-' * width);
  print(line('المجموع', subtotal));
  if (discount > 0) print(line('الخصم', -discount));
  print(line('الخدمة 12%', service));
  print(line('المطلوب', total));
  print('=' * width);
}

void main() {
  printReceipt(day: 'الجمعة', lattes: 2, cookies: 3);
  printReceipt(day: 'الاثنين', cakes: 1, lattes: 1);
}
