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

  // الشرط ? إن تحقق : إن لم يتحقق، للاختيارات الصغيرة.
  var kind = age < 18 ? 'طفل' : 'بالغ';
  var who = isMember ? 'عضو' : 'زائر';
  print('العمر $age ($kind، $who) يدفع $price');
}
