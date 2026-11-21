void main() {
  // عُدّ من 1 إلى 3.
  for (var i = 1; i <= 3; i++) {
    print('الدورة $i');
  }

  // for-in: كل عنصر في القائمة، بالترتيب.
  var drinks = ['شاي', 'قهوة', 'عصير'];
  for (var drink in drinks) {
    print(drink);
  }

  // while: كرّر ما دام الشرط صحيحاً.
  var cups = 3;
  while (cups > 0) {
    print('الكوب $cups');
    cups--;
  }

  // continue تقفز إلى الدورة التالية؛ وbreak تخرج من الحلقة.
  for (var n = 1; n <= 10; n++) {
    if (n % 2 == 0) continue;
    if (n > 7) break;
    print(n);
  }
}
